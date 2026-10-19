-- This book spell selects one of seven source projectile types each cast.
local destruction = require("policy.combat.monster_spells.destruction")

local effect = {}

-- Tracer selection happens before committing the monster action.
function effect.plan(ctx, caster, foe)
    return destruction.plan_major(ctx, caster, foe)
end

-- The source selects the actual projectile after its tracer cast.
function effect.resolve(ctx, caster, foe, _, plan)
    return destruction.resolve_major(ctx, caster, foe, plan)
end

return effect
