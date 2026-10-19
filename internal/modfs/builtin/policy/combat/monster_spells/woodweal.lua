local healing = require("policy.combat.monster_support.healing")
local self_target = require("policy.combat.monster_support.self_target")

local woodweal = {}

-- Source Woodweal requires both a wound and adjacent tree or mangrove.
function woodweal.plan(ctx, caster)
    if not healing.wounded(ctx, caster) or
        not healing.near_wood(ctx, caster) then
        return nil
    end

    return self_target.plan(caster)
end

-- Healing leaves the tree in place for later turns and other monsters.
function woodweal.resolve(ctx, caster, _, _, plan)
    self_target.require_caster(plan, caster)

    healing.woodweal(ctx, caster)
end

return woodweal
