local component = require("constants.component")
local monster_stats = require("policy.combat.monster_stats")
local hand = require("policy.combat.monster_support.trogs_hand")

local will = {}

-- Example: A monster with willpower 5000 is immune before the two spell resistance dice are rolled.
-- Treat source sentinel willpower as an immunity gate before enchant power consumes resistance dice.
function will.invulnerable(definition)
    return (definition.willpower or 0) >= 5000
end

-- Source: actor.cc:check_willpower and beam.cc:ench_power_stepdown.
-- Monster casts pass their saved stream; player spells retain the ordinary
-- spell stream when the optional argument is absent.
function will.resists(ctx, definition, enchant_power, target, stream)
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
        resistance = resistance + hand.will_bonus(ctx, target)

        local lowered = ctx:get(target, component.MONSTER_LOWERED_WILL)

        if lowered and lowered.remaining_aut > 0 then
            resistance = math.floor(resistance / 2)
        end
    end

    local stepped = math.floor(35 *
        math.log(1 + enchant_power / 35) / math.log(2) + 0.5)
    local threshold = 100 + resistance - stepped
    local chosen_stream = stream or "spell"
    local roll = ctx:random(chosen_stream, 100) +
        ctx:random(chosen_stream, 101)

    return threshold - roll > 0
end

return will
