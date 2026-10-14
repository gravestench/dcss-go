local equipment = require("policy.combat.equipment")
local fighter = require("policy.combat.fighter")
local roll = require("policy.combat.roll")

local delay = {}

local function rounded_values(numerator, denominator)
    local whole = math.floor(numerator / denominator)
    local remainder = numerator % denominator
    local values = {
        { value = whole, weight = denominator - remainder },
    }

    if remainder > 0 then
        values[#values + 1] = { value = whole + 1, weight = remainder }
    end

    return values
end

function delay.minimum_weapon(speed, skill_id)
    local minimum = math.floor(speed / 2)

    if skill_id == "SK_SHORT_BLADES" then
        minimum = math.min(minimum, 5)
    end

    return math.max(3, math.min(minimum, 7), speed - 14)
end

function delay.minimum_skill(speed, skill_id)
    return 2 * (speed - delay.minimum_weapon(speed, skill_id))
end

function delay.player(ctx, time_taken)
    local attack = fighter.attack(ctx, { ev = 0, ac = 0 })
    local worn = equipment.worn(ctx, ctx:player(), { shield = true })
    local shield_ev = worn.shield and worn.shield.definition.armour.ev or 0
    local shields10 = fighter.skill(ctx, "SK_SHIELDS", 10)
    local weapon10 = fighter.skill(ctx, attack.weapon_skill, 10)
    local base = attack.unarmed and 10 or attack.weapon_speed
    local reduction = weapon10
    local denominator = 54

    if not attack.unarmed then
        local minimum = delay.minimum_weapon(attack.weapon_speed, attack.weapon_skill)
        reduction = math.min(weapon10, 20 * (attack.weapon_speed - minimum))
        denominator = 20
    end

    local shield_base = math.floor(-shield_ev / 10)
    local shield_penalty20 = math.floor(
        2 * shield_base ^ 2 * (270 - shields10) * 20 / 100 / 270)
    local weights = {}
    local low = math.huge
    local high = 0

    -- The source combines random_var distributions before making one melee draw.
    for _, skill in ipairs(rounded_values(reduction, denominator)) do
        for _, shield in ipairs(rounded_values(shield_penalty20, 20)) do
            local action = math.max(2, math.max(3, base - skill.value) + shield.value)

            for _, scaled in ipairs(rounded_values(action * time_taken, 10)) do
                local value = math.max(2, scaled.value)
                weights[value] = (weights[value] or 0) +
                    skill.weight * shield.weight * scaled.weight
                low = math.min(low, value)
                high = math.max(high, value)
            end
        end
    end

    local total = 0

    for value = low, high do
        total = total + (weights[value] or 0)
    end

    local draw = roll.melee(ctx, total)

    for value = low, high do
        if draw < (weights[value] or 0) then
            return value
        end

        draw = draw - (weights[value] or 0)
    end

    error("attack delay distribution was empty")
end

return delay
