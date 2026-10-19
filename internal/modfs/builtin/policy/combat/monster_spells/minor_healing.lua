local healing = require("policy.combat.monster_support.healing")
local self_target = require("policy.combat.monster_support.self_target")

local minor_healing = {}

-- Minor Healing is worth a source monster spell slot only below half HP.
function minor_healing.plan(ctx, caster)
    if not healing.wounded(ctx, caster) then
        return nil
    end

    return self_target.plan(caster)
end

-- The source healing beam adds a small fixed amount after its two dice.
function minor_healing.resolve(ctx, caster, _, _, plan)
    self_target.require_caster(plan, caster)

    healing.minor(ctx, caster)
end

return minor_healing
