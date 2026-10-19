local self_target = require("policy.combat.monster_support.self_target")
local wind = require("policy.combat.monster_support.still_winds")

local still_winds = {}

-- Source AI avoids an idle level-wide cloud shutdown with no tactical use.
function still_winds.plan(ctx, caster)
    if not wind.useful(ctx, caster) then
        return nil
    end

    return self_target.plan(caster)
end

-- The caster-owned aura clears existing clouds and gates new placements.
function still_winds.resolve(ctx, caster, _, _, plan)
    self_target.require_caster(plan, caster)

    wind.cast(ctx, caster)
end

return still_winds
