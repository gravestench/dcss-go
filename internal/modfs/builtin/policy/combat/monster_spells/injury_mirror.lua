local mirror = require("policy.combat.monster_support.injury_mirror")
local self_target = require("policy.combat.monster_support.self_target")

local injury_mirror = {}

-- The saved absolute recast time filters an otherwise useful self spell.
function injury_mirror.plan(ctx, caster)
    if not mirror.ready(ctx, caster) then
        return nil
    end

    return self_target.plan(caster)
end

-- The aura and its later recast lock begin on the selected spell action.
function injury_mirror.resolve(ctx, caster, _, _, plan)
    self_target.require_caster(plan, caster)

    mirror.cast(ctx, caster)
end

return injury_mirror
