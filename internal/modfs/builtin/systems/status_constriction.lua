-- Theory of operation: a direct grip lives on its victim, regardless of
-- whether that victim is the player or a monster. Each active source turn
-- validates all linked victims, deals ramping damage, then advances time.
local catalog = require("policy.catalog")
local component = require("constants.component")
local constriction = require("policy.combat.constriction")
local fighter = require("policy.combat.fighter")
local monster_defense = require("policy.combat.monster_defense")
local monster_health = require("policy.combat.monster_health")
local monster_profile = require("policy.combat.monster_profile")
local player_health = require("policy.combat.player_health")
local sequence = require("policy.combat.monster_attack_sequence")
local attack_types = require("constants.monster_attack_types")
local targets = require("policy.ai.targets")

local system = {}

-- A changed floor, dead participant, or missing body ends the grip before
-- the next constrictor damage tick. The victim owns the removable link.
local function valid(ctx, victim, grip)
    local source = ctx:get(grip.by, component.POSITION)
    local target = ctx:get(victim, component.POSITION)
    local source_health = ctx:get(grip.by, component.HEALTH)
    local target_health = ctx:get(victim, component.HEALTH)

    return source and target and source_health and target_health and
        source_health.current > 0 and target_health.current > 0 and
        source.level_id == target.level_id and
        math.max(math.abs(source.x - target.x),
            math.abs(source.y - target.y)) == 1
end

-- A polymorphed constrictor may lose the slot that formed the hold.
-- Re-read the current attack sequence rather than trusting saved damage.
local function attack(ctx, source)
    local actor = ctx:get(source, component.ACTOR)

    if not actor then
        return nil
    end

    local base = catalog.get("monsters", actor.kind_id)
    local definition = monster_profile.definition(ctx, source, base)

    for _, selected in ipairs(sequence.for_actor(ctx, source,
        definition)) do
        if selected.attack.type_id == attack_types.CONSTRICT then
            return selected.attack, definition, actor
        end
    end

    return nil
end

-- Resolve one saved victim through the normal player or monster HP owner.
-- The latter can credit an allied constrictor with the eventual kill.
local function tick(ctx, victim, grip, strike, definition, actor,
    elapsed_aut)
    local player = ctx:has(victim, component.PLAYER)
    local defender = player and fighter.defense(ctx) or nil
    local victim_definition

    if not player then
        local current = ctx:get(victim, component.ACTOR)
        local base = catalog.get("monsters", current.kind_id)

        victim_definition = monster_profile.definition(ctx, victim, base)
        defender = {
            ac = monster_defense.armour(ctx, victim,
                victim_definition),
        }
    end

    local amount = constriction.damage(ctx, strike.damage,
        defender.ac, actor.speed, grip.held_aut)
    local health

    if player then
        health = player_health.damage(ctx, victim, amount,
            false, grip.by)
        ctx:emit("combat", "The " .. definition.name ..
            " constricts you.")
    else
        health = monster_health.damage(ctx, victim, amount,
            grip.by)
        ctx:emit("combat", "The " .. definition.name ..
            " constricts the " .. victim_definition.name .. ".")

        if health.current == 0 and targets.allied(ctx, grip.by) then
            ctx:signal("player_kill", victim)
        end
    end

    if health.current == 0 then
        ctx:remove(victim, component.CONSTRICTION)

        return
    end

    grip.held_aut = grip.held_aut + math.max(0, elapsed_aut or 10)
    ctx:set(victim, component.CONSTRICTION, grip)
end

-- Every action may clear stale links; only the source's action damages its
-- still adjacent victims. This also supports an octopode's many tentacles.
function system.update(ctx, active, elapsed_aut)
    for _, victim in ipairs(ctx:query({ component.CONSTRICTION })) do
        local grip = ctx:get(victim, component.CONSTRICTION)

        if not valid(ctx, victim, grip) then
            ctx:remove(victim, component.CONSTRICTION)
        elseif active == grip.by then
            local strike, definition, actor = attack(ctx, grip.by)

            if not strike then
                ctx:remove(victim, component.CONSTRICTION)
            else
                tick(ctx, victim, grip, strike, definition, actor,
                    elapsed_aut)
            end
        end
    end
end

register.system({
    id = "status.constriction",
    scope = "active",
    query = {},
    after = { "attack.combat" },
    before = { "actor.death" },
    update = system.update,
})

return system
