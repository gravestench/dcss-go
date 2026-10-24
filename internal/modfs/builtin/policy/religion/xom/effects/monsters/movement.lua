-- Xom relocates monsters and swaps occupied cells through the grid owner.
local catalog = require("policy.catalog")
local component = require("constants.component")
local confusion = require("policy.religion.xom.confusion")
local events = require("ids.xom_events")
local flags = require("constants.monster_flags")
local groups = require("constants.monster_groups")
local flight = require("policy.combat.flight")
local habitat = require("policy.combat.monster_habitat")
local landing = require("policy.combat.monster_displacement.landing")
local relocate = require("policy.combat.monster_displacement.relocate")
local streams = require("constants.rng_streams")
local terrain = require("constants.terrain")
local water = require("policy.character.water")
local xom_state = require("policy.religion.xom.state")

local effect = {}

-- Monster flags live on the catalog definition, not the actor component.
local function has_flag(definition, wanted)
    for _, flag in ipairs(definition.flags or {}) do
        if flag == wanted then
            return true
        end
    end

    return false
end

-- A Xom blink targets hostiles that could actually be displaced. This
-- eligibility is shared with the selector so an impossible action is not
-- chosen merely because a stationary projectile was nearby.
function effect.blink_candidates(ctx, player)
    local candidates = {}

    for _, monster in ipairs(confusion.nearby(ctx, player)) do
        local actor = ctx:get(monster, component.ACTOR)
        local definition = actor and catalog.get("monsters", actor.kind_id)

        if definition and confusion.hostile(ctx, monster) and
            not has_flag(definition, flags.PROJECTILE) and
            relocate.can_move(ctx, monster) then
            candidates[#candidates + 1] = monster
        end
    end

    return candidates
end

-- Source chooses the whole wave's direction once, then skips each victim
-- independently. The common displacement owner checks habitat and leaves
-- the ordinary blink cloud; at most five successful victims are counted.
local function blink_monsters(ctx, player, stream)
    local worship = ctx:get(player, component.RELIGION_WORSHIP)
    local toward_player = xom_state.feels_nasty(worship) or
        ctx:random(stream, 2) == 0
    local origin = ctx:get(player, component.POSITION)
    local count = 0

    for _, monster in ipairs(effect.blink_candidates(ctx, player)) do
        if count >= 5 then
            break
        end

        if ctx:random(stream, 2) == 0 then
            local x, y

            if toward_player then
                x, y = landing.weighted(ctx, monster, origin,
                    true, true, stream)
            else
                x, y = landing.ordinary(ctx, monster, false, stream)
            end

            if x and relocate.move(ctx, monster, x, y, player) then
                count = count + 1
            end
        end
    end

    return count
end

-- A real swap changes two occupied positions atomically. The grid command
-- checks both destinations together; two single-actor moves would collide.
local function swap(ctx, first, second)
    local a = ctx:get(first, component.POSITION)
    local b = ctx:get(second, component.POSITION)

    if not a or not b or a.level_id ~= b.level_id then
        return false
    end

    ctx:move_actors({
        {
            actor = first,
            level_id = a.level_id,
            x = b.x,
            y = b.y,
        },
        {
            actor = second,
            level_id = b.level_id,
            x = a.x,
            y = a.y,
        },
    })

    return true
end

-- The player may enter only a safe terrain cell, even when the other
-- occupant is moved away in the same grid batch.
local function safe_player_cell(ctx, player, position)
    if not ctx:walkable(position.level_id, position.x, position.y) then
        return false
    end

    if flight.active(ctx, player) then
        return true
    end

    local feature = ctx:cell(position.level_id, position.x, position.y)

    return feature ~= terrain.DNGN_LAVA and
        (feature ~= terrain.DNGN_DEEP_WATER or
            water.can_swim(ctx, player))
end

-- Exclude tentacles and bodies that cannot stand on the player's square.
-- Other stationary monsters remain eligible if their habitat permits it;
-- the source's rearrangeable-pieces gate excludes only tentacles here.
function effect.swap_candidates(ctx, player)
    local origin = ctx:get(player, component.POSITION)
    local candidates = {}

    if not origin then
        return candidates
    end

    for _, monster in ipairs(confusion.nearby(ctx, player)) do
        local position = ctx:get(monster, component.POSITION)
        local actor = ctx:get(monster, component.ACTOR)
        local definition = actor and catalog.get("monsters", actor.kind_id)

        if position and definition and
            not groups.tentacles[definition.id] and
            safe_player_cell(ctx, player, position) and
            habitat.at(ctx, monster, origin.level_id,
                origin.x, origin.y) then
            candidates[#candidates + 1] = monster
        end
    end

    return candidates
end

-- Extra severity can shuffle up to eight other monster pairs after the
-- player trade. Their ECS positions remain saved by the ordinary owner.
local function rearrange(ctx, player, severity, stream)
    local candidates = effect.swap_candidates(ctx, player)
    local count = #candidates

    if count == 0 then
        return false
    end

    local chosen = candidates[ctx:random(stream, count) + 1]

    swap(ctx, player, chosen)

    if ctx:random(stream, 2) == 0 then
        confusion.monster(ctx, chosen, severity, stream)
    end

    local extra_swaps = false

    if count > 1 then
        extra_swaps = severity >= 70 or
            ctx:random(stream, 70) < severity
    end

    if count > 1 and extra_swaps then
        local cap = math.min(math.floor(count / 2), 8)
        local range = math.floor(severity / 10)
        local repeats = 1

        if range > 1 then
            repeats = ctx:random(stream, range) + 1
        end

        repeats = math.min(repeats, cap)

        for _ = 1, repeats do
            local first = ctx:random(stream, count) + 1
            local second = first

            while second == first do
                second = ctx:random(stream, count) + 1
            end

            if swap(ctx, candidates[first], candidates[second]) then
                if ctx:random(stream, 4) == 0 then
                    confusion.monster(ctx, candidates[first],
                        severity, stream)
                end

                if ctx:random(stream, 4) == 0 then
                    confusion.monster(ctx, candidates[second],
                        severity, stream)
                end
            end
        end
    end

    return true
end

-- Blink and swap share spatial eligibility, but keep their source draws.
function effect.apply(ctx, player, event_id, severity, request)
    local stream = request and request.stream or streams.RELIGION

    if event_id == events.BAD_BLINK_MONSTERS then
        return blink_monsters(ctx, player, stream)
    end

    if event_id == events.BAD_SWAP_MONSTERS then
        return rearrange(ctx, player, severity, stream)
    end

    error("movement effect received another Xom event")
end

return effect
