local fighter = require("policy.combat.fighter")
local delay = require("policy.combat.delay")

local practice = {}

-- Certain and impossible practice gates consume no skill RNG, preserving the stream.
local function chance(ctx, numerator, denominator)
    if numerator <= 0 then
        return false
    end

    if denominator <= 0 or numerator >= denominator then
        return true
    end

    return ctx:random("skill", denominator) < numerator
end

-- Fractional undertraining bonus gets unbiased skill-stream rounding.
local function random_round(ctx, numerator, denominator)
    local whole = math.floor(numerator / denominator)
    local remainder = numerator % denominator
    local roll = ctx:random("skill", denominator)

    return whole + (roll < remainder and 1 or 0)
end

-- Practice is a signal for progression; combat does not directly mutate XP.
local function emit(ctx, id)
    ctx:signal("practice", id)
end

-- Train more below the minimum-delay skill threshold, then still occasionally train Fighting.
local function weapon_use(ctx, input)
    -- Skill below the weapon's minimum delay threshold receives more
    -- practice; each emitted event is handled by the progression system.
    local minimum = input.minimum_skill or
        delay.minimum_skill(input.weapon_speed, input.weapon_skill)
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

-- Example: practice.player_hit(ctx, input) with unarmed hit -> Unarmed Combat practice event
-- Unarmed hits train directly; wielded hits use weapon damage as the practice gate.
function practice.player_hit(ctx, input)
    if input.unarmed then
        emit(ctx, "SK_UNARMED_COMBAT")

        return
    end

    if not chance(ctx, input.weapon_damage, 20) then
        return
    end

    weapon_use(ctx, input)
end

-- Committed throws train even on misses; launchers share weapon-delay practice logic.
function practice.player_projectile(ctx, missile, launcher)
    -- exercise.cc trains on the committed shot, even when it misses.
    if not launcher then
        if missile.id ~= "MI_STONE" or chance(ctx, 1, 2) then
            emit(ctx, "SK_THROWING")
        end

        return
    end

    if not chance(ctx, 1, 2) then
        return
    end

    local weapon = launcher.weapon
    local input = {
        weapon_skill = weapon.skill_id,
        weapon_speed = weapon.speed,
        weapon100 = fighter.skill(ctx, weapon.skill_id, 100),
        minimum_skill = 2 * (weapon.speed - delay.minimum_launcher(launcher)),
    }

    weapon_use(ctx, input)
end

-- A blocked hit trains Shields more often than a non-blocked incoming attack.
function practice.incoming_shield(ctx, outcome, defense)
    if defense.shield_class <= 0 then
        return
    end

    local denominator = outcome.kind == "block" and 2 or 6

    if chance(ctx, 1, denominator) then
        emit(ctx, "SK_SHIELDS")
    end
end

-- Armour mass suppresses Dodging, while real hits can train Armour or Fighting.
function practice.incoming_melee(ctx, outcome, defense)
    -- Armour mass suppresses Dodging practice, while actual hits may train
    -- Armour or Fighting after the shield practice check.
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
