local fighter = require("policy.combat.fighter")
local delay = require("policy.combat.delay")

local practice = {}

local function chance(ctx, numerator, denominator)
    if numerator <= 0 then
        return false
    end

    if denominator <= 0 or numerator >= denominator then
        return true
    end

    return ctx:random("skill", denominator) < numerator
end

local function random_round(ctx, numerator, denominator)
    local whole = math.floor(numerator / denominator)
    local remainder = numerator % denominator
    local roll = ctx:random("skill", denominator)

    return whole + (roll < remainder and 1 or 0)
end

local function emit(ctx, id)
    ctx:signal("practice", id)
end

function practice.player_hit(ctx, input)
    if input.unarmed then
        emit(ctx, "SK_UNARMED_COMBAT")

        return
    end

    if not chance(ctx, input.weapon_damage, 20) then
        return
    end

    local minimum = delay.minimum_skill(input.weapon_speed, input.weapon_skill)
    local current = math.floor(input.weapon100 / 100)
    local degree = 0

    if current >= minimum then
        degree = chance(ctx, 1, 2) and 1 or 0
    else
        degree = 1

        if minimum > 0 then
            degree = degree + random_round(ctx, 2 * (minimum - current), minimum)
        end
    end

    for _ = 1, degree do
        emit(ctx, input.weapon_skill)
    end

    if chance(ctx, 1, 2) then
        emit(ctx, "SK_FIGHTING")
    end
end

function practice.incoming_shield(ctx, outcome, defense)
    if defense.shield_class <= 0 then
        return
    end

    local denominator = outcome.kind == "block" and 2 or 6

    if chance(ctx, 1, denominator) then
        emit(ctx, "SK_SHIELDS")
    end
end

function practice.incoming_melee(ctx, outcome, defense)
    local armour_mass = math.max(0, 42 * math.floor(-defense.body_ev / 10) - 13)

    if chance(ctx, 1, 6) and not chance(ctx, armour_mass, 800) then
        emit(ctx, "SK_DODGING")
    end

    practice.incoming_shield(ctx, outcome, defense)

    if outcome.kind ~= "hit" then
        return
    end

    if chance(ctx, 1, 2) then
        local armour_level = fighter.skill_level(ctx, "SK_ARMOUR")

        if chance(ctx, armour_mass - 100, armour_level * 50) then
            local degree = ctx:random("skill", 2) + 1

            for _ = 1, degree do
                emit(ctx, "SK_ARMOUR")
            end
        end
    elseif chance(ctx, 1, 2) then
        emit(ctx, "SK_FIGHTING")
    end
end

return practice
