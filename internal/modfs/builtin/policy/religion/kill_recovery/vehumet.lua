-- Vehumet returns MP on eligible kills. This god's formula is separate
-- from the shared eligibility rule so a sparse mod can replace it alone.
local roll = require("policy.religion.kill_recovery.roll")
local stats = require("policy.combat.monster_stats")

local vehumet = {}

-- Source grants one MP plus random2 of half the victim's original HD.
function vehumet.amounts(ctx, victim, definition)
    local hd = stats.base_hit_dice(ctx, victim, definition)
    local mp = 1 + roll.random(ctx, math.floor(hd / 2))

    return 0, mp
end

return vehumet
