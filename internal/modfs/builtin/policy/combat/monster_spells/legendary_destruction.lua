-- Legendary Destruction releases two weighted fire, ice, or negative
-- energy explosions during one monster action.
local destruction = require("policy.combat.monster_spells.destruction")

local effect = {}

-- Plan a safe blast cell using the first source profile draw.
function effect.plan(ctx, caster, foe)
    return destruction.plan_legendary(ctx, caster, foe)
end

-- Each blast draws its own profile and stops if the foe was killed.
function effect.resolve(ctx, caster, foe, _, plan)
    return destruction.resolve_legendary(ctx, caster, foe, plan)
end

return effect
