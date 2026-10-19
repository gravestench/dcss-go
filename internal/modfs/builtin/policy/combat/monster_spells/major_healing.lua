local healing = require("policy.combat.monster_support.healing")
local self_target = require("policy.combat.monster_support.self_target")

local major_healing = {}

-- An ordinary monster does not spend a powerful heal above half HP.
function major_healing.plan(ctx, caster)
    if not healing.wounded(ctx, caster) then
        return nil
    end

    return self_target.plan(caster)
end

-- The shared healing owner clamps HP and preserves the monster's ECS state.
function major_healing.resolve(ctx, caster, _, _, plan)
    self_target.require_caster(plan, caster)

    healing.major(ctx, caster)
end

return major_healing
