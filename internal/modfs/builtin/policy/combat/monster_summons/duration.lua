local roll = require("policy.combat.roll")
local streams = require("constants.rng_streams")

local duration = {}

-- Source mon-ench.cc:_mod_speed scales each abjuration degree by the
-- summoned actor's speed, rather than by its caster's action speed.
local function mod_speed(value, speed)
    return math.max(1, math.floor(value * 10 / speed))
end

-- Source speed_to_duration stochastically rounds 100/speed. This draw is
-- kept on the monster-spell stream with the later duration fuzz.
local function speed_duration(ctx, speed)
    local quotient = math.floor(100 / speed)
    local remainder = 100 % speed

    if remainder > 0 and
        roll.draw(ctx, streams.MONSTER_SPELL, speed) < remainder then
        quotient = quotient + 1
    end

    return quotient
end

-- ENCH_ABJ first computes the source degree's nominal duration, then
-- fuzzes it asymmetrically from 60% below to 40% above. The two widened
-- random2avg draws give the source's roughly 90% mean duration.
function duration.abjuration(ctx, degree, actor_speed)
    if degree < 1 or degree > 6 then
        error("monster summon abjuration degree must be one through six")
    end

    local speed = math.max(1, math.min(actor_speed or 10, 100))
    local turns = math.floor(1000 * math.min(4, degree) /
        mod_speed(100, speed))

    if degree >= 5 then
        turns = turns + math.floor(1000 / mod_speed(20, speed))
    end

    if degree >= 6 then
        turns = turns + math.floor(1000 / mod_speed(10, speed))
    end

    local raw = math.max(2, turns) * speed_duration(ctx, speed)
    local lower = math.floor(raw * 60 / 100)
    local upper = math.floor(raw * 40 / 100)
    local width = lower + upper + 1
    local first = roll.draw(ctx, streams.MONSTER_SPELL, width)
    local second = roll.draw(ctx, streams.MONSTER_SPELL, width + 1)
    local fuzz = math.floor((first + second) / 2)

    return math.max(15, raw + fuzz - lower)
end

return duration
