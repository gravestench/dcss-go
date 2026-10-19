local spells = require("ids.spells")
local monsters = require("ids.monsters")
local component = require("constants.component")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local intent_ids = require("constants.intent")
local streams = require("constants.rng_streams")
local blast = require("policy.magic.effects.summons.blast")
local registry = require("policy.magic.effects.registry")
local summons = require("policy.magic.effects.summons.common")
local senses = require("policy.character.senses")
local vision = require("policy.character.vision")

local foxfire = {}

-- A foxfire may reach a cell its summoner cannot see. Source contact aborts
-- unless the living summoner sees both the construct and its victim's cell.
local function owner_sees_contact(ctx, owner, origin, target)
    local health = ctx:get(owner, component.HEALTH)
    local owner_position = ctx:get(owner, component.POSITION)
    local target_position = ctx:get(target, component.POSITION)

    if not health or health.current <= 0 or
        not owner_position or not target_position or
        owner_position.level_id ~= origin.level_id or
        owner_position.level_id ~= target_position.level_id then
        return false
    end

    local radius = owner == ctx:player() and
        vision.radius(ctx, owner) or 7

    return ctx:visible(origin.level_id,
        owner_position.x, owner_position.y, radius,
        origin.x, origin.y) and
        ctx:visible(origin.level_id,
            owner_position.x, owner_position.y, radius,
            target_position.x, target_position.y)
end

-- ZAP_FOXFIRE has separate player and monster damage dice. Both cap power
-- at 50, but hostile foxfire rolls three smaller dice rather than one die.
local function contact_damage(ctx, owner, power, stream)
    local capped = math.min(power, 50)

    if owner == ctx:player() then
        return 1 + ctx:random(stream,
            4 + math.floor(capped / 5))
    end

    local sides = 3 + math.floor(capped / 12)
    local total = 0

    for _ = 1, 3 do
        total = total + 1 + ctx:random(stream, sides)
    end

    return total
end

-- Preparation needs one free neighboring cell even though resolve attempts to place two foxfires.
local function space(ctx, player)
    local origin = ctx:get(player, component.POSITION)

    for dx = -1, 1 do
        for dy = -1, 1 do
            if (dx ~= 0 or dy ~= 0) and
                ctx:walkable(origin.level_id, origin.x + dx, origin.y + dy) and
                not ctx:actor_at(origin.level_id, origin.x + dx, origin.y + dy) then
                return true
            end
        end
    end

    return false
end

-- Close to a visible hostile, fire once and mark finished; otherwise route toward it without occupying its cell.
function foxfire.act(ctx, entity, origin)
    local state = ctx:get(entity, component.SUMMON_CONSTRUCT)
    local summon = ctx:get(entity, component.SUMMON)

    if state.charge >= 1 then
        return { kind = intent_ids.MONSTER_WAIT }
    end

    local target, distance = blast.nearest_hostile(ctx, entity,
        origin, 7)

    if target and distance == 1 then
        if not owner_sees_contact(ctx, summon.owner, origin, target) then
            return { kind = intent_ids.MONSTER_WAIT }
        end

        local stream = summon.owner == ctx:player() and
            streams.SPELL or streams.MONSTER_SPELL
        local raw = contact_damage(ctx, summon.owner,
            state.power, stream)

        -- Source: zap-data.h:ZAP_FOXFIRE; contact is automatic, then AC
        -- and fire resistance apply in the shared blast damage path.
        blast.hit(ctx, target, raw, "MR_RES_FIRE", entity, stream)
        blast.finish(ctx, entity, 1)

        if summon.owner == ctx:player() then
            ctx:emit("combat", "Your foxfire strikes a nearby creature.")
        elseif senses.player_sees_actor(ctx, entity) then
            ctx:emit("combat", "The foxfire strikes a nearby creature.")
        end

        return {
            kind = intent_ids.MONSTER_ABILITY,
            spell_id = summon.source_id,
        }
    end

    if target then
        local destination = ctx:get(target, component.POSITION)
        local dx, dy, found = ctx:route_step(origin.level_id,
            origin.x, origin.y, destination.x, destination.y, target)

        if found and ctx:walkable(origin.level_id,
            origin.x + dx, origin.y + dy) and
            not ctx:actor_at(origin.level_id,
                origin.x + dx, origin.y + dy) then
            return { kind = intent_ids.MONSTER_MOVE, dx = dx, dy = dy }
        end
    end

    return { kind = intent_ids.MONSTER_WAIT }
end

-- Example: Foxfire rejects a cast when no nearby placement cell is available.
-- Source: spl-summoning.cc:cast_foxfire creates two adjacent, short-lived
-- foxfires and rejects a completely enclosed caster before spending time.
function foxfire.prepare(ctx, player)
    if not space(ctx, player) then
        return "There is not enough space to conjure foxfire!"
    end
end

-- Both spell sources call this owner-neutral creation path. The saved summon
-- source distinguishes player Foxfire from monster Marshlight on later turns.
function foxfire.spawn(ctx, owner, source_id, power, cap)
    local created = 0

    for _ = 1, 2 do
        local creature = summons.spawn(ctx, owner,
            source_id, monsters.MONS_FOXFIRE, 0, cap, {
                expires_aut = ctx:aut() + 60,
            })

        if creature then
            ctx:add(creature, component.SUMMON_CONSTRUCT, {
                power = power,
                charge = 0,
            })
            created = created + 1
        end
    end

    if created > 0 and owner == ctx:player() then
        ctx:emit("spell", "You conjure some foxfire!")
    elseif created > 0 and senses.player_sees_actor(ctx, owner) then
        local actor = ctx:get(owner, component.ACTOR)
        local definition = catalog.get(categories.MONSTERS,
            actor.kind_id)

        ctx:emit("spell", "The " .. definition.name ..
            " conjures some foxfire!")
    end

    return created
end

-- Player Foxfire keeps its existing cap and spell identity.
function foxfire.resolve(ctx, player, _, _, power)
    foxfire.spawn(ctx, player, spells.SPELL_FOXFIRE, power, 12)
end

registry.add(spells.SPELL_FOXFIRE, {
    prepare = foxfire.prepare,
    resolve = foxfire.resolve,
})

return foxfire
