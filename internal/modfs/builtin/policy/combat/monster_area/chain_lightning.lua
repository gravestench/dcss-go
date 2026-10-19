-- Chain Lightning is one actor-neutral sequence of lightning rays. The
-- nearest visible worthwhile body starts it; each struck target may arc to
-- unseen-by-player actors within three cells, including the original caster.
-- The source zap uses thunder, so each ray can hit intervening actors too.
-- Source: spl-damage.cc:_find_closest_target and _chain_lightning_to.
-- Example: chain.resolve(ctx, caster, power, profile, stream, kind) may
-- damage an actor on the ray before the chosen next target.
local accuracy = require("constants.beam_accuracy")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local channels = require("constants.message_channels")
local component = require("constants.component")
local contact = require("policy.combat.monster_beams.contact")
local flags = require("constants.monster_flags")
local roll = require("policy.combat.roll")
local trajectory = require("policy.combat.trajectory")

local chain = {}
local SIGHT_RADIUS = 7
local ARC_RADIUS = 3
local DICE = 3
local MAX_POWER = 200

-- The source ignores conjured and no-threat monsters. A player remains a
-- valid victim, and the caster itself may be reached by a later jump.
local function worthwhile(ctx, target)
    local health = ctx:get(target, component.HEALTH)

    if not health or health.current <= 0 then
        return false
    end

    if ctx:has(target, component.PLAYER) then
        return true
    end

    local actor = ctx:get(target, component.ACTOR)

    if not actor then
        return false
    end

    local definition = catalog.get(categories.MONSTERS,
        actor.kind_id)

    for _, flag in ipairs(definition.flags or {}) do
        if flag == flags.CONJURED or
            flag == flags.NO_THREAT then
            return false
        end
    end

    return true
end

-- Chebyshev distance is DCSS grid distance for the seven-cell initial
-- search and each three-cell jump from a previous arc target.
local function distance(first, second)
    return math.max(math.abs(first.x - second.x),
        math.abs(first.y - second.y))
end

-- The caster must see every candidate through clear walls. The current
-- arc source needs ordinary solid-wall LOS, but actors on the ray may be
-- hit rather than making the planned target ineligible.
local function candidates(ctx, caster, source, radius, seen)
    local origin = ctx:get(caster, component.POSITION)
    local found = {}

    for _, target in ipairs(ctx:query({
        component.ACTOR,
        component.POSITION,
        component.HEALTH,
    })) do
        if not seen[target] and worthwhile(ctx, target) then
            local position = ctx:get(target, component.POSITION)
            local from_source = distance(source, position)

            if position.level_id == source.level_id and
                from_source > 0 and from_source <= radius and
                distance(origin, position) <= SIGHT_RADIUS and
                ctx:visible_no_trans(origin.level_id,
                    origin.x, origin.y, SIGHT_RADIUS,
                    position.x, position.y) and
                ctx:visible(source.level_id,
                    source.x, source.y, radius,
                    position.x, position.y) then
                found[#found + 1] = {
                    entity = target,
                    position = position,
                    distance = from_source,
                }
            end
        end
    end

    return found
end

-- The source's fair nearest-target iterator chooses randomly only among
-- the bodies at the shortest reachable distance.
local function first_target(ctx, caster, stream)
    local origin = ctx:get(caster, component.POSITION)

    if not origin then
        return nil
    end

    local nearest = {}
    local distance_to_nearest = SIGHT_RADIUS + 1
    local seen = {
        [caster] = true,
    }

    for _, entry in ipairs(candidates(ctx,
        caster, origin, SIGHT_RADIUS, seen)) do
        if entry.distance < distance_to_nearest then
            nearest = { entry }
            distance_to_nearest = entry.distance
        elseif entry.distance == distance_to_nearest then
            nearest[#nearest + 1] = entry
        end
    end

    if #nearest == 0 then
        return nil
    end

    return nearest[ctx:random(stream, #nearest) + 1]
end

-- The same zap has different player and monster dice. Player casts divide
-- a calculated 2*power total among three dice; monster casts use the
-- source's 27 + power/12 die size.
local function base_sides(ctx, power, stream, caster_is_player)
    local capped = math.min(power, MAX_POWER)

    if caster_is_player then
        return roll.random_divide(ctx, 2 * capped, DICE, stream)
    end

    return 27 + math.floor(capped / 12)
end

-- Each recursion recomputes the zap's base sides, then attenuates by the
-- first target's range and 3/5 for every completed jump wave.
local function arc_sides(ctx, power, stream,
    caster_is_player, first_distance, wave_index)
    local sides = base_sides(ctx, power, stream,
        caster_is_player)

    sides = math.floor(sides *
        0.6 ^ ((first_distance - 1) / 3))

    for _ = 1, wave_index do
        sides = math.floor(sides * 3 / 5)
    end

    return sides
end

-- Give this ray its own dice size without mutating the registered zap.
-- The existing beam contact owner handles half AC, half-resistible thunder,
-- attributed HP, and any actor between source and planned target.
local function strike(ctx, caster, source, target,
    profile, power, stream, sides)
    local ray_profile = {}

    for key, value in pairs(profile) do
        ray_profile[key] = value
    end

    ray_profile.rng_stream = stream
    ray_profile.monster_damage = {
        kind = "dicedef",
        args = {
            DICE,
            sides,
            0,
            1,
        },
    }

    local ray = trajectory.to_target(ctx, source.level_id,
        source.x, source.y,
        target.x, target.y,
        distance(source, target))

    for _, hit in ipairs(ray.contacts) do
        contact.resolve(ctx, caster, hit.actor,
            ray_profile, power, accuracy.AUTOMATIC_HIT)
    end
end

-- Return false when no worthwhile body is in range. Otherwise visit jump
-- waves in source order; only intended arc targets enter the seen set, so
-- an intervening actor can still be selected by a later jump.
function chain.resolve(ctx, caster, power, profile, stream, start_message)
    local first = first_target(ctx, caster, stream)

    if not first then
        return false
    end

    if start_message then
        ctx:emit(channels.SPELL, start_message)
    end

    local seen = {
        [first.entity] = true,
    }
    local wave = {
        first,
    }
    local first_distance = first.distance
    local caster_is_player = ctx:has(caster, component.PLAYER)
    local wave_index = 0

    while #wave > 0 do
        local next_wave = {}
        local sides = arc_sides(ctx, power, stream,
            caster_is_player, first_distance, wave_index)

        for _, entry in ipairs(wave) do
            local source = wave_index == 0 and
                ctx:get(caster, component.POSITION) or
                entry.source
            local strike_sides = entry.entity == caster and
                math.floor(sides / 6) or sides

            strike(ctx, caster, source, entry.position,
                profile, power, stream, strike_sides)

            for _, candidate in ipairs(candidates(ctx,
                caster, entry.position, ARC_RADIUS, seen)) do
                seen[candidate.entity] = true
                candidate.source = entry.position
                next_wave[#next_wave + 1] = candidate
            end
        end

        wave = next_wave
        wave_index = wave_index + 1
    end

    return true
end

return chain
