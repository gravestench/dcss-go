local fighter = require("policy.combat.fighter")
local player_attack = require("policy.combat.player_attack")
local roll = require("policy.combat.roll")

local melee = {}

function melee.player(ctx, input)
    return player_attack.resolve(ctx, input)
end

local function headbutt_damage(ctx, input)
    local base = 5 + input.horns * 3
    local potential = math.floor(base * math.max(2, 150 + 5 * input.strength) / 2 / 100)
    local damage = roll.melee(ctx, potential)
    local fighting = roll.melee(ctx, input.fighting100 + 1)
    damage = math.floor(damage * (4000 + fighting) / 4000)

    if input.mighty then
        damage = damage + 1 + roll.melee(ctx, 10)
    end

    local saved = roll.armour(ctx, input.defender_ac)

    return math.max(0, damage - saved)
end

function melee.headbutt_input(ctx, defender)
    local player = ctx:player()
    local attributes = ctx:get(player, "core.attributes")
    local progress = ctx:get(player, "core.progression")
    local durations = ctx:get(player, "core.durations")

    return {
        level = progress.level,
        horns = fighter.mutation(ctx, "MUT_HORNS"),
        reflexive = fighter.mutation(ctx, "MUT_REFLEXIVE_HEADBUTT") > 0,
        strength = attributes.strength,
        dexterity = attributes.dexterity,
        fighting100 = fighter.skill(ctx, "SK_FIGHTING", 100),
        fighting30 = fighter.skill(ctx, "SK_FIGHTING", 30),
        defender_ev = defender.ev or 0,
        defender_ac = defender.ac or 0,
        mighty = durations and durations.might_aut > 0 or false,
    }
end

function melee.auxiliary_headbutt(ctx, input)
    if input.horns == 0 then
        return { attempted = false }
    end

    local chance = math.floor(67 * (30 + input.level) / 59)

    if roll.melee(ctx, 100) >= chance then
        return { attempted = false }
    end

    local hit_base = math.floor((1300 + input.dexterity * 75 + input.fighting30) / 100)
    local to_hit = roll.melee(ctx, hit_base)
    local auto_hit = roll.melee(ctx, 30)

    if to_hit < input.defender_ev and auto_hit ~= 0 then
        return { attempted = true, hit = false }
    end

    roll.melee(ctx, 15 + math.floor(to_hit / 2))

    return {
        attempted = true,
        hit = true,
        damage = headbutt_damage(ctx, input),
    }
end

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
        damage = headbutt_damage(ctx, input),
    }
end

local function contact(ctx, hd, hit, plus, defense)
    local to_hit = roll.melee(ctx, 19 + math.floor(hd * 3 / 2) + hit + plus)
    local ev_roll = roll.average_two(ctx, "melee", 2 * defense.ev)
    local auto_chance = roll.melee(ctx, 100)
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

    if not auto_hit and to_hit < ev_roll then
        return { kind = "dodge", damage = 0, shield_blocks = defense.shield_blocks }
    end

    return { kind = "hit", damage = 0, shield_blocks = defense.shield_blocks }
end

function melee.monster(ctx, attack, defense)
    local weapon = attack.weapon
    local outcome = contact(ctx, attack.hd, weapon and weapon.hit or 0,
        weapon and weapon.plus or 0, defense)

    if outcome.kind ~= "hit" or attack.type_id == "AT_CONSTRICT" then
        return outcome
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
    local saved = roll.gdr_armour(ctx, defense, potential)
    outcome.damage = math.max(0, damage - saved)

    return outcome
end

return melee
