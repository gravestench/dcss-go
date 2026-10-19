-- Example: One Missing Eye rank lowers a physical contact roll before the hit comparison.
local capabilities = require("constants.mutation_capabilities")
local effects = require("policy.mutations.effects.registry")

local accuracy = {}

-- Sum Eyeballs-style attack bonuses from active mutation effects before physical hit rolls.
function accuracy.hit_bonus(ctx, player)
    return effects.sum(ctx, player, capabilities.ATTACK_HIT_BONUS)
end

-- Sum Inaccuracy ranks once so melee and aimed zaps use the same penalty source.
function accuracy.degree(ctx, player)
    return effects.sum(ctx, player, capabilities.INACCURACY)
end

-- Source: attack.cc:post_roll_to_hit_modifiers. A missed eye is applied
-- after the player's melee hit roll, including auxiliary attacks.
function accuracy.melee_to_hit(ctx, player, rolled)
    return rolled - 5 * accuracy.degree(ctx, player)
end

-- Source: beam.cc:zap_to_hit. Aimed player zaps clamp at zero; automatic
-- hit and enchantment zaps bypass this calculation in their callers.
-- Clamp aimed zap accuracy after Inaccuracy; automatic hits never call this path.
function accuracy.zap_to_hit(ctx, player, base)
    return math.max(0, base - 5 * accuracy.degree(ctx, player))
end

return accuracy
