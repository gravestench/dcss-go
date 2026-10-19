-- Wall of Brambles is a geometry spell with a saved foe and placement plan.
local brambles = require("policy.combat.monster_plants.brambles")

local effect = {}

-- The source refuses a wall that cannot provide cover or block escape.
function effect.plan(ctx, caster, foe)
    return brambles.plan(ctx, caster, foe)
end

-- The plant owner places each patch and assigns its own expiry timer.
function effect.resolve(ctx, caster, foe, _, plan)
    brambles.raise(ctx, caster, foe, plan)
end

return effect
