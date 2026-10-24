-- Makhleb restores HP from a victim's original hit dice, unaffected by
-- temporary draining. The shared kill owner handles piety and capacity.
local roll = require("policy.religion.kill_recovery.roll")
local stats = require("policy.combat.monster_stats")

local makhleb = {}

-- The first term guarantees at least one HP; the second is source
-- random2(hd / 2), which does not draw when the bound is zero.
function makhleb.amounts(ctx, victim, definition)
    local hd = stats.base_hit_dice(ctx, victim, definition)
    local hp = math.floor((1 + hd) / 2) +
        roll.random(ctx, math.floor(hd / 2))

    return hp, 0
end

return makhleb
