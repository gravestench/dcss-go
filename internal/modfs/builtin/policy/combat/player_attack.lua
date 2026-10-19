local roll = require("policy.combat.roll")
local forms = require("policy.magic.effects.forms.player")
local statuses = require("policy.magic.effects.statuses.player")
local accuracy = require("policy.character.accuracy")
local stab = require("policy.combat.stab")
local weakness = require("policy.combat.player_weakness")
local size = require("constants.size")

local player_attack = {}

-- Reconstruct monster SH from equipment and body size before testing a player strike.
local function shield_bonus(ctx, shield)
    local body_size = size.rank[shield.size]

    if not body_size then
        error("unsupported monster shield body size " .. tostring(shield.size))
    end

    -- monster.cc rolls monster SH from shield AC, enchantment,
    -- body size, and HD. A nonpositive result cannot block.
    local base = (shield.ac + shield.plus * 2) * 2 +
        (body_size - size.rank[size.MEDIUM]) * (shield.subtype - 14)
    local bound = base + math.floor(shield.hit_dice * 4 / 3)

    if bound <= 0 then
        return -100
    end

    local bonus = math.floor(roll.average_two(ctx, "melee", bound) / 2)

    return bonus > 0 and bonus or -100
end

-- Source: attack.cc:attack_shield_blocked. The bypass roll precedes the
-- defender's shield roll, and each successful block raises later penalties.
function player_attack.shield_contact(ctx, input, to_hit)
    local shield = input.defender_shield
    local penalty = shield and 4 * shield.blocks * shield.blocks or 0
    local bypass = roll.melee(ctx, 15 + math.floor(to_hit / 2) + penalty)
    local bonus = shield and shield_bonus(ctx, shield) or -100
    local would_block = bonus >= bypass

    return would_block and not input.penetrating,
        would_block and input.penetrating
end

-- Preserve fractional skill contributions through a melee-stream roll.
local function maybe_random_div(ctx, numerator, denominator)
    if numerator <= 0 then
        return 0
    end

    return math.floor(roll.melee(ctx, numerator + denominator) / denominator)
end

-- Resolve player accuracy, dodge, and shield outcomes before damage or brands can run.
function player_attack.contact(ctx, input)
    local fighting = maybe_random_div(ctx, input.fighting100, 100)
    local weapon_skill = maybe_random_div(ctx, input.weapon100, 100)
    local hit_base = 15 + math.floor(input.dexterity / 2) + fighting +
        weapon_skill + (input.slay or 0) + (input.hit_bonus or 0) +
        statuses.confusing_touch_hit_bonus(ctx, ctx:player(), input.dexterity) +
        accuracy.hit_bonus(ctx, ctx:player())

    if statuses.vertigo_active(ctx, ctx:player()) then
        hit_base = hit_base - 5
    end

    if not input.using_weapon then
        hit_base = hit_base + 2
    else
        hit_base = hit_base + input.weapon_hit + input.weapon_plus
    end

    local to_hit = roll.melee(ctx, hit_base)
    to_hit = accuracy.melee_to_hit(ctx, ctx:player(), to_hit)

    -- ranged-attack.cc halves post-roll projectile accuracy against Repel
    -- Missiles. Melee callers do not set this input field.
    if input.missile_repulsion then
        to_hit = to_hit - math.floor((hit_base + 1) / 2)
    end

    local auto_chance = roll.melee(ctx, 100)
    local auto_miss = false
    local auto_hit = false

    if auto_chance < 5 then
        local coin = roll.melee(ctx, 2)
        auto_miss = coin == 0
        auto_hit = coin ~= 0
    end

    local blocked, pierced_shield = player_attack.shield_contact(ctx,
        input, to_hit)

    if blocked then
        return { kind = "block", damage = 0 }
    end

    if auto_miss or (not auto_hit and to_hit < input.defender_ev) then
        return { kind = "miss", damage = 0, pierced_shield = pierced_shield }
    end

    return { kind = "hit", damage = 0, pierced_shield = pierced_shield }
end

-- Example: player_attack.damage(ctx, input) with input.unarmed -> uses form and Unarmed Combat damage
-- Roll weapon or unarmed potential only after contact and apply strength and Fighting before armour.
function player_attack.damage(ctx, input)
    local potential = input.weapon_damage

    if input.unarmed then
        potential = forms.unarmed_base(ctx, ctx:player()) +
            math.floor(input.unarmed256 / 256)
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

    local corrosion = require("policy.combat.player_corrosion")
    local slaying = input.weapon_plus + (input.slay or 0) -
        corrosion.penalty(ctx, ctx:player())

    if slaying >= 0 then
        damage = damage + roll.melee(ctx, 1 + slaying)
    else
        damage = damage - roll.melee(ctx, 1 - slaying)
    end

    if input.roll_distance and input.roll_distance > 0 then
        local extra = math.floor(damage * input.roll_distance / 3)
        damage = damage + math.min(damage, extra)
    end

    damage = stab.damage(ctx, ctx:player(), input, input.stab_plan, damage)

    -- Source Weak scales raw melee power before AC, including stab hits.
    damage = weakness.melee_damage(ctx, ctx:player(), damage)

    local saved = roll.armour(ctx, input.defender_ac)

    return statuses.confusing_touch_damage(ctx, ctx:player(),
        math.max(0, damage - saved))
end

-- Prepare stab state before contact effects, then apply damage only to a confirmed hit.
function player_attack.resolve(ctx, input)
    local outcome = player_attack.contact(ctx, input)

    if input.stab_target then
        input.stab_plan = stab.prepare(ctx, ctx:player(),
            input.stab_target, input)

        if input.stab_plan.bonus > 0 then
            outcome.kind = "hit"
            outcome.pierced_shield = false
        end
    end

    if outcome.kind == "hit" then
        outcome.damage = player_attack.damage(ctx, input)
    end

    return outcome
end

return player_attack
