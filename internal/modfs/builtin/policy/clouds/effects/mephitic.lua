local categories = require("constants.catalog")
local component = require("constants.component")
local zap_ids = require("policy.magic.effects.zaps.ids")
local catalog = require("policy.catalog")
local poison = require("policy.combat.monster_poison")
local resistance = require("policy.combat.player_resistance")
local roll = require("policy.combat.roll")
local monster_stats = require("policy.combat.monster_stats")
local streams = require("constants.rng_streams")
local intelligence = require("constants.monster_intelligence")

local mephitic = {}

-- Careful pathing avoids confusion exposure even when the monster is not poison-immune.
function mephitic.avoid(ctx, actor, _, careful)
    if careful then
        return true
    end

    local state = ctx:get(actor, component.ACTOR)
    local definition = catalog.get(categories.MONSTERS, state.kind_id)

    if definition.intelligence_id == intelligence.BRAINLESS then
        return false
    end

    local hd = monster_stats.hit_dice(ctx, actor, definition)

    if hd >= 6 then
        return false
    end

    return ctx:random(streams.CLOUDS, 5) >= hd - 1
end

-- Poison resistance blocks mephitic confusion before any cloud RNG roll.
function mephitic.immune(ctx, target)
    if target == ctx:player() then
        return resistance.poison(ctx, target) > 0
    end

    local actor = ctx:get(target, component.ACTOR)

    return not actor or poison.resistance(
        catalog.get(categories.MONSTERS, actor.kind_id)) > 0
end

-- Confusion duration scales with monster speed and HD when cloud power is zero.
local function monster_duration(ctx, target, actor, definition)
    -- mon-ench.cc:ENCH_CONFUSION falls back to its speed/HD duration when
    -- cloud.cc applies BEAM_CONFUSION with enchant power zero.
    local speed = math.max(1, math.min(100, actor.speed))
    local hd = monster_stats.hit_dice(ctx, target, definition)
    local modded = math.max(1, math.floor((hd + 5) * 10 / speed))
    local centiturns = math.max(3, math.floor(100 / modded))
    local raw = centiturns * roll.random_divide(ctx, 100,
        speed, streams.CLOUDS)
    local low = math.floor(60 * raw / 100)
    local high = math.floor(40 * raw / 100)

    return math.max(15, raw + roll.average_two(ctx, streams.CLOUDS,
        low + high + 1) - low)
end

-- Apply immunity and clarity gates before a level-based confusion roll on each exposure.
-- Example: a susceptible actor can gain confusion after a mephitic-cloud exposure roll.
function mephitic.apply(ctx, target)
    if mephitic.immune(ctx, target) then
        return 0
    end

    if target == ctx:player() then
        if resistance.clarity(ctx, target) then
            return
        end

        local progression = ctx:get(target, component.PROGRESSION)

        if 1 + ctx:random(streams.CLOUDS, 27) < progression.level then
            return
        end

        local amount = (2 + ctx:random(streams.CLOUDS, 2)) * 10
        local state = ctx:get(target, zap_ids.component.PLAYER_CONFUSION)

        if state then
            state.remaining_aut = math.min(400,
                state.remaining_aut + amount)
            ctx:set(target, zap_ids.component.PLAYER_CONFUSION, state)
        else
            ctx:add(target, zap_ids.component.PLAYER_CONFUSION, {
                remaining_aut = amount,
            })
        end

        ctx:emit("cloud", "You choke on the stench!")
        return
    end

    local actor = ctx:get(target, component.ACTOR)
    local health = ctx:get(target, component.HEALTH)

    if not actor or not health or health.current <= 0 then
        return
    end

    local definition = catalog.get(categories.MONSTERS, actor.kind_id)

    -- cloud.cc:_mephitic_cloud_roll. High-HD monsters retain a 1/50 chance.
    local hd = monster_stats.hit_dice(ctx, target, definition)
    local affected

    if hd >= 21 then
        affected = ctx:random(streams.CLOUDS, 50) == 0
    else
        affected = ctx:random(streams.CLOUDS, 21) >= hd
    end

    if not affected then
        return
    end

    local duration = monster_duration(ctx, target, actor, definition)
    local state = ctx:get(target, component.MONSTER_CONFUSION)

    if state then
        state.remaining_aut = state.remaining_aut + duration
        ctx:set(target, component.MONSTER_CONFUSION, state)
    else
        ctx:add(target, component.MONSTER_CONFUSION, {
            remaining_aut = duration,
        })
    end

    ctx:emit("cloud", "The " .. definition.name .. " appears confused.")
end

return mephitic
