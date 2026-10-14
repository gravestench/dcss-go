local roll = require("policy.combat.roll")

local constriction = {}

function constriction.damage(ctx, base_damage, defender_ac, attacker_speed)
    local armour = roll.melee(ctx, 1 + math.floor(defender_ac / 2))
    local damage = math.max(0, base_damage - armour)

    return roll.random_divide(ctx, damage * 10, attacker_speed)
end

local function dice(ctx, count, sides)
    local total = 0

    for _ = 1, count do
        total = total + 1 + roll.melee(ctx, sides)
    end

    return total
end

function constriction.escape(ctx, attempts, attacker_hd)
    local escape_score = dice(ctx, 4 + attempts, 13)
    local hd_quarter = roll.random_divide(ctx, attacker_hd, 4)
    local grip_score = dice(ctx, 5, 8 + hd_quarter)

    return escape_score >= grip_score
end

return constriction
