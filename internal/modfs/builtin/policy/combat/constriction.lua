local roll = require("policy.combat.roll")

local constriction = {}

-- Armour is halved before the speed-scaled constriction damage roll.
function constriction.damage(ctx, base_damage, defender_ac, attacker_speed)
    local armour = roll.melee(ctx, 1 + math.floor(defender_ac / 2))
    local damage = math.max(0, base_damage - armour)

    return roll.random_divide(ctx, damage * 10, attacker_speed)
end

-- Sum independent melee dice for the escape contest instead of collapsing its distribution.
local function dice(ctx, count, sides)
    local total = 0

    for _ = 1, count do
        total = total + 1 + roll.melee(ctx, sides)
    end

    return total
end

-- Example: with more failed attempts,
-- constriction.escape(ctx, attempts, attacker_hd) -> more escape dice on next contest
-- Repeated escape attempts add dice; attacker hit dice increase the competing grip die size.
function constriction.escape(ctx, attempts, attacker_hd)
    local escape_score = dice(ctx, 4 + attempts, 13)
    local hd_quarter = roll.random_divide(ctx, attacker_hd, 4)
    local grip_score = dice(ctx, 5, 8 + hd_quarter)

    return escape_score >= grip_score
end

return constriction
