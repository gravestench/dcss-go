local roll = require("policy.combat.roll")

local player_attack = {}

local size_value = {
    SIZE_LITTLE = 1,
    SIZE_SMALL = 2,
    SIZE_MEDIUM = 3,
    SIZE_LARGE = 4,
    SIZE_GIANT = 5,
}

local function shield_bonus(ctx, shield)
    local size = size_value[shield.size]

    if not size then
        error("unsupported monster shield body size " .. tostring(shield.size))
    end

    -- monster.cc:2996-3029 rolls monster SH from shield AC, enchantment,
    -- body size, and HD. A nonpositive result cannot block.
    local base = (shield.ac + shield.plus * 2) * 2 +
        (size - size_value.SIZE_MEDIUM) * (shield.subtype - 14)
    local bound = base + math.floor(shield.hit_dice * 4 / 3)

    if bound <= 0 then
        return -100
    end

    local bonus = math.floor(roll.average_two(ctx, "melee", bound) / 2)

    return bonus > 0 and bonus or -100
end

local function maybe_random_div(ctx, numerator, denominator)
    if numerator <= 0 then
        return 0
    end

    return math.floor(roll.melee(ctx, numerator + denominator) / denominator)
end

function player_attack.contact(ctx, input)
    local fighting = maybe_random_div(ctx, input.fighting100, 100)
    local weapon_skill = maybe_random_div(ctx, input.weapon100, 100)
    local hit_base = 15 + math.floor(input.dexterity / 2) + fighting + weapon_skill

    if not input.using_weapon then
        hit_base = hit_base + 2
    else
        hit_base = hit_base + input.weapon_hit + input.weapon_plus
    end

    local to_hit = roll.melee(ctx, hit_base)
    local auto_chance = roll.melee(ctx, 100)
    local auto_miss = false
    local auto_hit = false

    if auto_chance < 5 then
        local coin = roll.melee(ctx, 2)
        auto_miss = coin == 0
        auto_hit = coin ~= 0
    end

    local shield = input.defender_shield
    local bonus = shield and shield_bonus(ctx, shield) or -100
    local penalty = shield and 4 * shield.blocks * shield.blocks or 0
    local bypass = roll.melee(ctx, 15 + math.floor(to_hit / 2) + penalty)

    if bonus >= bypass and not input.penetrating then
        return { kind = "block", damage = 0 }
    end

    local pierced_shield = bonus >= bypass and input.penetrating

    if auto_miss or (not auto_hit and to_hit < input.defender_ev) then
        return { kind = "miss", damage = 0, pierced_shield = pierced_shield }
    end

    return { kind = "hit", damage = 0, pierced_shield = pierced_shield }
end

function player_attack.damage(ctx, input)
    local potential = input.weapon_damage

    if input.unarmed then
        potential = 3 + math.floor(input.unarmed256 / 256)
        local remainder = input.unarmed256 % 256

        if remainder ~= 0 and roll.melee(ctx, 256) < remainder then
            potential = potential + 1
        end
    end

    local stat = input.damage_attribute or input.strength

    if not input.damage_attribute and not input.unarmed and
        (input.weapon_skill == "SK_SHORT_BLADES" or input.weapon_skill == "SK_LONG_BLADES") then
        stat = input.dexterity
    end

    potential = math.floor(potential * math.max(2, 150 + 5 * stat) / 2 / 100)
    local damage = roll.melee(ctx, potential + 1)

    if input.using_weapon then
        local bonus = roll.melee(ctx, input.weapon100 + 1)
        damage = math.floor(damage * (2500 + bonus) / 2500)
    end

    local fighting_bonus = roll.melee(ctx, input.fighting100 + 1)
    damage = math.floor(damage * (3000 + fighting_bonus) / 3000)

    if input.mighty then
        damage = damage + 1 + roll.melee(ctx, 10)
    end

    if input.weapon_plus >= 0 then
        damage = damage + roll.melee(ctx, 1 + input.weapon_plus)
    else
        damage = damage - roll.melee(ctx, 1 - input.weapon_plus)
    end

    local saved = roll.armour(ctx, input.defender_ac)

    return math.max(0, damage - saved)
end

function player_attack.resolve(ctx, input)
    local outcome = player_attack.contact(ctx, input)

    if outcome.kind == "hit" then
        outcome.damage = player_attack.damage(ctx, input)
    end

    return outcome
end

return player_attack
