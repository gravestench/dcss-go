local component = require("constants.component")
local roll = require("policy.combat.roll")

local duration = {}

-- Source mon-ench.cc scales beneficial enchantments by the monster's speed,
-- using 25 instead of HD so a high-HD caster does not get a shorter buff.
local function modified_speed(value, speed)
    local actual_speed = speed == 0 and 10 or speed

    return math.max(1, math.floor(value * 10 / actual_speed))
end

-- One monster action represents a stochastic fraction of ordinary 10-aut
-- time. Keep the rounding draw on the spell stream for save continuation.
local function speed_to_duration(ctx, speed)
    local bounded = speed < 1 and 10 or math.min(100, speed)

    return roll.random_divide(ctx, 100, bounded, "monster_spell")
end

-- The source's asymmetric fuzz spans 40% through 140% of the raw duration.
-- The two average draws are made only when a real cast applies the effect.
local function fuzz(ctx, raw)
    local low = math.floor(60 * raw / 100)
    local high = math.floor(40 * raw / 100)
    local average = roll.average_two(ctx, "monster_spell", low + high + 1)

    return math.max(15, raw + average - low)
end

-- Example: a speed-10 monster's Haste is based on 40 centiturns before fuzz.
-- Haste, Might, Invisibility, and Swift share this source duration class.
function duration.beneficial(ctx, monster)
    local actor = ctx:get(monster, component.ACTOR)

    if not actor then
        error("monster self-enchantment has no actor")
    end

    local centiturns = math.max(2,
        math.floor(1000 / modified_speed(25, actor.speed)))
    local raw = centiturns * speed_to_duration(ctx, actor.speed)

    return fuzz(ctx, raw)
end

-- Protective enchantments use the shorter 300-centiturn source class.
function duration.protection(ctx, monster)
    local actor = ctx:get(monster, component.ACTOR)

    if not actor then
        error("monster protection spell has no actor")
    end

    local centiturns = math.max(2,
        math.floor(300 / modified_speed(25, actor.speed)))
    local raw = centiturns * speed_to_duration(ctx, actor.speed)

    return fuzz(ctx, raw)
end

-- Aura of Brilliance and its recipient empowerment each use 20 source
-- centiturns adjusted by the actor's own speed, then the common fuzz.
function duration.brilliance(ctx, monster)
    local actor = ctx:get(monster, component.ACTOR)

    if not actor then
        error("monster brilliance has no actor")
    end

    local centiturns = math.max(2,
        math.floor(200 / modified_speed(10, actor.speed)))
    local raw = centiturns * speed_to_duration(ctx, actor.speed)

    return fuzz(ctx, raw)
end

return duration
