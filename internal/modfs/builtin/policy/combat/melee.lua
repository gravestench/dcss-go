local auxiliary = require("policy.combat.auxiliary")
local player_attack = require("policy.combat.player_attack")
local roll = require("policy.combat.roll")
local enfeeble = require("policy.magic.effects.statuses.enfeeble")
local shadowstab = require("policy.combat.monster_shadowstab")
local flavours = require("constants.attack_flavours")

local melee = {}

-- Example: melee.player(ctx, input) with confirmed player hit -> resolved hit and damage outcome
-- Forward a prepared player attack to contact and damage resolution in one call.
function melee.player(ctx, input)
    return player_attack.resolve(ctx, input)
end

-- Reflexive headbutts require horns and make their own chance roll before auxiliary damage.
function melee.reflexive_headbutt(ctx, input)
    if not input.reflexive or input.horns == 0 then
        return { attempted = false }
    end

    if roll.melee(ctx, 100) >= 23 + input.level then
        return { attempted = false }
    end

    return {
        attempted = true,
        hit = true,
        damage = auxiliary.damage(ctx, input, 5 + input.horns * 3),
    }
end

-- Shield blocking is rolled before the auto miss and evasion checks; preserve this RNG order.
local function contact(ctx, hd, hit, plus, defense, automatic)
    local hit_bound = 19 + math.floor(hd * 3 / 2) + hit + plus +
        (defense.visible_hit_modifier or 0)
    local to_hit = automatic and 0 or roll.melee(ctx, hit_bound)
    local ev_roll = roll.average_two(ctx, "melee", 2 * defense.ev)
    local auto_chance = automatic and 100 or roll.melee(ctx, 100)
    local auto_miss = false
    local auto_hit = false

    if auto_chance < 5 then
        local coin = roll.melee(ctx, 2)
        auto_miss = coin == 0
        auto_hit = coin ~= 0
    end

    local bypass = 15 + math.floor(hd * 2 / 3) + 5 * defense.shield_blocks ^ 2
    local con_block = roll.melee(ctx, bypass)
    local pro_block = -100

    if defense.shield_class > 0 then
        local shield_roll = roll.average_two(ctx, "melee", defense.shield_class * 2)
        pro_block = math.floor(shield_roll / 3) - 1
    end

    if pro_block >= con_block then
        return { kind = "block", damage = 0, shield_blocks = defense.shield_blocks + 1 }
    end

    if auto_miss then
        return { kind = "miss", damage = 0, shield_blocks = defense.shield_blocks }
    end

    if not automatic and not auto_hit and to_hit < ev_roll then
        return { kind = "dodge", damage = 0, shield_blocks = defense.shield_blocks }
    end

    return { kind = "hit", damage = 0, shield_blocks = defense.shield_blocks }
end

-- Convert a selected monster weapon into the shared contact roll without dealing damage yet.
function melee.monster_contact(ctx, attack, defense)
    local weapon = attack.weapon
    local automatic = attack.flavour_id == flavours.SHADOWSTAB and
        attack.attacker and attack.defender and
        shadowstab.unseen(ctx, attack.attacker, attack.defender)
    local outcome = contact(ctx, attack.hd, weapon and weapon.hit or 0,
        weapon and weapon.plus or 0, defense, automatic)

    if automatic then
        shadowstab.announce(ctx, attack.attacker, attack.defender)
        outcome.darkness = true
    end

    return outcome
end

-- Damage rolls after contact use the monster's selected attack profile.
function melee.monster_damage(ctx, attack, defense)
    local weapon = attack.weapon

    if attack.type_id == "AT_CONSTRICT" then
        return 0
    end

    local weapon_damage = 0
    local potential = attack.damage

    if weapon then
        weapon_damage = roll.melee(ctx, weapon.damage)
        local slay = roll.melee(ctx, 1 + math.abs(weapon.plus))
        weapon_damage = weapon_damage + (weapon.plus < 0 and -slay or slay)
        potential = potential + weapon.damage
    end

    local base = roll.melee(ctx, attack.damage)
    local damage = weapon_damage + 1 + base

    -- Source Weak scales a monster's raw strike before the defender's AC.
    -- `attacker` is optional for pure contact fixtures without an actor.
    if attack.attacker then
        damage = enfeeble.melee_damage(ctx, attack.attacker, damage)
    end

    damage = shadowstab.damage(ctx, attack, damage)

    local saved = roll.gdr_armour(ctx, defense, potential)
    return math.max(0, damage - saved)
end

-- Damage is rolled only after a hit so misses and blocks do not consume damage RNG.
function melee.monster(ctx, attack, defense)
    local outcome = melee.monster_contact(ctx, attack, defense)

    if outcome.kind == "hit" then
        outcome.damage = melee.monster_damage(ctx, attack, defense)
    end

    return outcome
end

return melee
