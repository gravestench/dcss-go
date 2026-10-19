local repulsion = require("policy.combat.monster_support.repulsion")
local self_target = require("policy.combat.monster_support.self_target")

local repel_missiles = {}

-- A monster with an active repulsion enchantment cannot use this slot again.
function repel_missiles.plan(ctx, caster)
    if repulsion.active(ctx, caster) then
        return nil
    end

    return self_target.plan(caster)
end

-- Beam and physical projectile contact both consult the saved marker.
function repel_missiles.resolve(ctx, caster, _, _, plan)
    self_target.require_caster(plan, caster)

    repulsion.apply(ctx, caster)
end

return repel_missiles
