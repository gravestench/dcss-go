local roll = require("policy.combat.roll")
local component = require("constants.component")

local constriction = {}

-- Source actor.cc ramps a direct hold as its saved duration grows. The
-- logarithmic stepdown slows late damage growth before armour and speed.
function constriction.damage(ctx, base_damage, defender_ac,
    attacker_speed, held_aut)
    local duration = held_aut or 0
    local stepdown = 50 * math.log(1 + duration / 50) /
        math.log(2)
    local ramp = roll.random_divide(ctx,
        math.floor(base_damage * stepdown), 50)
    local armour = roll.melee(ctx, 1 + math.floor(defender_ac / 2))
    local damage = math.max(0, base_damage + ramp - armour)

    return roll.random_divide(ctx, damage * 10, attacker_speed)
end

-- A monster facing another monster's grip uses its own source contest:
-- each failed escape adds three to its score against grip HD and two dice.
function constriction.monster_escape(ctx, attempts, attacker_hd)
    local grip = 5 + 1 + roll.melee(ctx, 5) +
        1 + roll.melee(ctx, math.max(1, attacker_hd))

    return 3 * attempts > grip
end

-- Death can occur after this status's active tick. Clear every reference
-- before actor deletion so the next save never points at a dead holder.
function constriction.release_for(ctx, dying)
    for _, victim in ipairs(ctx:query({ component.CONSTRICTION })) do
        local grip = ctx:get(victim, component.CONSTRICTION)

        if victim == dying or grip.by == dying then
            ctx:remove(victim, component.CONSTRICTION)
        end
    end
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
