local component = require("constants.component")
local capabilities = require("constants.mutation_capabilities")
local effects = require("policy.mutations.effects.registry")
local statuses = require("policy.magic.effects.statuses.player")
local player_health = require("policy.combat.player_health")
local mirror = require("policy.combat.monster_support.injury_mirror")
local bond = require("policy.combat.monster_injury_bond")
local display = require("policy.combat.monster_support.display")
local causes = require("constants.damage_causes")
local senses = require("policy.character.senses")
local awareness = require("policy.ai.awareness")
local catalog = require("policy.catalog")
local gods = require("constants.gods")

local monster_health = {}

-- Damage to a spectral weapon can propagate to its owner unless the owner caused the hit.
local function share_spectral_damage(ctx, target, source, dealt)
    if dealt < 2 or not source or
        not ctx:has(target, component.SPECTRAL_WEAPON) then
        return
    end

    local summon = ctx:get(target, component.SUMMON)
    local owner = summon and summon.owner

    if not owner or source == owner or
        not ctx:has(owner, component.PLAYER) then
        return
    end

    local health = ctx:get(owner, component.HEALTH)
    local shared = math.min(math.floor(dealt / 2), health.current - 1)

    if shared > 0 then
        ctx:emit("combat", "Your spectral weapon shares its damage with you!")
        player_health.damage(ctx, owner, shared, false)
    end
end

-- Example: monster_health.damage(ctx, target, amount, source) with already dead target -> no further HP loss
-- Shared monster HP loss lets mutation effects observe damage actually
-- dealt after petrification, with an explicit source actor.
function monster_health.damage(ctx, target, amount, source, cause)
    local health = ctx:get(target, component.HEALTH)

    if not health then
        error("monster damage target has no health")
    end

    local before = health.current

    if before <= 0 then
        return health, 0
    end

    statuses.wake_hibernating(ctx, target)
    amount = statuses.petrified_damage(ctx, target, amount)

    -- Source damage splits after petrification and before the protected
    -- monster loses HP. The redirected hit has its own cause so it cannot
    -- pass through another bond or trigger a second reflection.
    local guardian, shared

    amount, guardian, shared = bond.split(ctx, target, amount,
        cause or causes.ORDINARY)

    local dealt = math.min(before, math.max(0, amount))

    -- Monster::hurt offers Uskayaw only direct, XP-bearing foe damage.
    -- Delayed poison, clouds, and shared pain cannot build dance momentum.
    local worship = source and ctx:has(source, component.PLAYER) and
        ctx:get(source, component.RELIGION_WORSHIP)

    if dealt > 0 and worship and worship.god_id == gods.USKAYAW and
        cause ~= causes.POISON and cause ~= causes.CLOUD and
        cause ~= causes.INJURY_BOND then
        local actor = ctx:get(target, component.ACTOR)
        local definition = catalog.get("monsters", actor.kind_id)
        local facts = require("policy.religion.conduct.monster_facts")
        local event = facts.hurt(ctx, target, definition, dealt, health.max)

        if event then
            require("policy.religion.conduct").record(ctx, event)
        end
    end

    health.current = before - dealt
    ctx:set(target, component.HEALTH, health)

    if dealt > 0 and health.current > 0 then
        awareness.wake_from_damage(ctx, target, source)
    end

    if guardian then
        monster_health.damage(ctx, guardian, shared, source,
            causes.INJURY_BOND)
    end

    share_spectral_damage(ctx, target, source, dealt)

    if dealt > 0 and health.current > 0 and source and
        ctx:has(source, component.PLAYER) then
        local hit = {
            target = target,
            damage = dealt,
        }

        effects.trigger(ctx, source, capabilities.AFTER_MONSTER_DAMAGE, hit)
    end

    local returned = mirror.returned(ctx, target, dealt, source,
        cause or causes.ORDINARY)

    if returned > 0 then
        if senses.player_sees_actor(ctx, target) then
            ctx:emit("combat", "The " .. display.name(ctx, target) ..
                " mirrors the damage!")
        end

        if ctx:has(source, component.PLAYER) then
            player_health.damage(ctx, source, returned, false, target)
        else
            monster_health.damage(ctx, source, returned, target,
                causes.REFLECTED)
        end
    end

    return health, dealt
end

return monster_health
