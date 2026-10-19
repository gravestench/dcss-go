-- The cast starts an actor-owned rolling enchantment. Movement and melee
-- consult that component on subsequent actions.
local roll = require("policy.combat.monster_roll")
local self_target = require("policy.combat.monster_support.self_target")

local effect = {}

-- A nearby foe or blocked route makes Roll a wasted self cast.
function effect.plan(ctx, caster, foe)
    if not roll.can_start(ctx, caster, foe) then
        return nil
    end

    return self_target.plan(caster)
end

-- Keep the saved intent's caster identity authoritative across the cast.
function effect.resolve(ctx, caster, _, _, plan)
    self_target.require_caster(plan, caster)
    roll.start(ctx, caster)
end

return effect
