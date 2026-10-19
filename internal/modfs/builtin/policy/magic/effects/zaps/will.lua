local component = require("constants.component")
local monster_stats = require("policy.combat.monster_stats")

local will = {}

-- Example: A monster with willpower 5000 is immune before the two spell resistance dice are rolled.
-- Treat source sentinel willpower as an immunity gate before enchant power consumes resistance dice.
function will.invulnerable(definition)
    return (definition.willpower or 0) >= 5000
end

-- Source: actor.cc:check_willpower and beam.cc:ench_power_stepdown.
function will.resists(ctx, definition, enchant_power, target)
    local resistance = definition.willpower or 0

    if will.invulnerable(definition) then
        return true
    end

    -- Negative catalog values mean willpower per hit die in DCSS.
    if resistance < 0 then
        local hd = target and monster_stats.hit_dice(ctx, target, definition) or
            definition.hd

        resistance = math.floor(hd *
            -resistance * 4 / 3)
    end

    if target then
        local lowered = ctx:get(target, component.MONSTER_LOWERED_WILL)

        if lowered and lowered.remaining_aut > 0 then
            resistance = math.floor(resistance / 2)
        end
    end

    local stepped = math.floor(35 *
        math.log(1 + enchant_power / 35) / math.log(2) + 0.5)
    local threshold = 100 + resistance - stepped
    local roll = ctx:random("spell", 100) + ctx:random("spell", 101)

    return threshold - roll > 0
end

return will
