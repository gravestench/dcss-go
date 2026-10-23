-- Theory of operation: source cards derive one numeric power from Nemelex
-- piety and Invocations. Punishment uses experience level instead. Each
-- effect receives this value and rolls its own source power thresholds.
local component = require("constants.component")
local magic_power = require("policy.magic.power")
local skill_ids = require("ids.skills")
local streams = require("constants.rng_streams")

local power = {}

-- Integer division mirrors source arithmetic. The two skill scales have
-- distinct rounding, so one cannot be derived from the other afterward.
function power.value(ctx, player, punishment)
    if punishment then
        local progression = ctx:get(player, component.PROGRESSION)

        return progression.level * 18
    end

    local worship = ctx:get(player, component.RELIGION_WORSHIP)
    local piety = worship.piety
    local invocation100 = magic_power.training(ctx, player,
        skill_ids.SK_INVOCATIONS, 100)
    local invocation9 = magic_power.training(ctx, player,
        skill_ids.SK_INVOCATIONS, 9)

    return math.floor(piety * (invocation100 + 2500) / 2700) +
        invocation9 + math.floor(piety * 3 / 2)
end

-- Two independent x_chance_in_y checks produce the 0, 1, or 2 tier.
-- Certain and impossible chances skip their RNG draw in source DCSS.
function power.level(ctx, value)
    if value <= 0 then
        return 0
    end

    local first = value >= 900 or
        ctx:random(streams.CARDS, 900) < value
    local second = value >= 2700 or
        ctx:random(streams.CARDS, 2700) < value

    return (first and 1 or 0) + (second and 1 or 0)
end

return power
