local foe = require("policy.combat.monster_displacement.foe")

local effect = {}

-- Save the selected beam cell before the monster commits its action.
function effect.plan(ctx, caster, target)
    return foe.plan(ctx, caster, target)
end

-- A first contact that fails willpower stays put; a successful contact
-- uses the source's uncontrolled blink around the victim.
function effect.resolve(ctx, caster, _, _, plan)
    foe.enchant(ctx, caster, plan, false)
end

return effect
