local foe = require("policy.combat.monster_displacement.foe")

local effect = {}

-- Preserve beam direction to the original foe cell across intent saving.
function effect.plan(ctx, caster, target)
    return foe.plan(ctx, caster, target)
end

-- A successful enchantment draws the victim toward the caster using the
-- source close weighting instead of choosing an ordinary blink cell.
function effect.resolve(ctx, caster, _, _, plan)
    foe.enchant(ctx, caster, plan, true)
end

return effect
