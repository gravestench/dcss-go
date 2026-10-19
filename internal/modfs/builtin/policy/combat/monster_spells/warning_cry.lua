-- Warning Cry's whole gameplay effect is an audible alert. No status or
-- invisible placeholder effect is attached to nearby allies.
local cries = require("policy.combat.monster_battlecries")

local effect = {}

-- Friendly or silent monsters do not spend a warning action.
function effect.plan(ctx, caster)
    return cries.warning_plan(ctx, caster)
end

-- Pass the typed caster plan to the sound owner; its propagation updates
-- listener AI through the same path as shouts and alarms.
-- Example: a sentry cry redirects a wandering monster toward the origin.
function effect.resolve(ctx, caster, _, _, plan)
    cries.warning(ctx, caster, plan)
end

return effect
