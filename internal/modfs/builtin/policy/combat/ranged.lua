local roll = require("policy.combat.roll")
local player_attack = require("policy.combat.player_attack")

local ranged = {}

-- Apply missile repulsion before the monster hit roll, then compare against EV and shield.
local function contact(ctx, hd, weapon_hit, weapon_plus, defense)
    local hit_base = math.max(0, 18 + math.floor(hd * 3 / 2) + weapon_hit + weapon_plus)
    local modifier = defense.visible_hit_modifier or 0

    if defense.missile_repulsion then
        -- ranged-attack.cc applies this to the pre-roll monster hit value.
        modifier = modifier - math.floor((hit_base + 1) / 2)
    end

    local to_hit = roll.melee(ctx, hit_base + modifier + 1)
    local ev_roll = roll.average_two(ctx, "melee", 2 * defense.ev)
    local auto_chance = roll.melee(ctx, 100)
    local auto_miss = false
    local auto_hit = false

    if auto_chance < 5 then
        local coin = roll.melee(ctx, 2)
        auto_miss = coin == 0
        auto_hit = coin ~= 0
    end

    -- Source: attack.cc. The original shooter cannot shield
    -- against its own returned thrown or launched missile.
    if defense.skip_shield then
        -- The self-directed return proceeds directly to EV.
    elseif defense.monster_shield then
        local blocked = player_attack.shield_contact(ctx, {
            defender_shield = defense.monster_shield,
        }, to_hit)

        if blocked then
            return {
                kind = "block",
                damage = 0,
                shield_blocks = defense.shield_blocks + 1,
            }
        end
    else
        local bypass = 15 + math.floor(hd * 2 / 3) +
            5 * defense.shield_blocks ^ 2
        local con_block = roll.melee(ctx, bypass)
        local pro_block = -100

        if defense.shield_class > 0 then
            local shield = roll.average_two(ctx, "melee",
                defense.shield_class * 2)
            pro_block = math.floor(shield / 3) - 1
        end

        if pro_block >= con_block then
            return {
                kind = "block",
                damage = 0,
                shield_blocks = defense.shield_blocks + 1,
            }
        end
    end

    if auto_miss or (not auto_hit and to_hit < ev_roll) then
        return {
            kind = "dodge",
            damage = 0,
            shield_blocks = defense.shield_blocks,
        }
    end

    return {
        kind = "hit",
        damage = 0,
        shield_blocks = defense.shield_blocks,
    }
end

-- Example: ranged.shot(ctx, shot, defense) with shield-blocked shot -> block outcome without damage roll
-- Separate contact from damage so a blocked missile does not consume damage RNG.
function ranged.shot(ctx, shot, defense)
    local outcome = contact(ctx, shot.hd, shot.weapon_hit or 0,
        shot.weapon_plus or 0, defense)

    if outcome.kind ~= "hit" then
        return outcome
    end

    local plus = shot.weapon_plus or 0
    local potential = shot.weapon_damage + shot.projectile_damage
    local damage = roll.melee(ctx, potential)
    local enchantment = roll.melee(ctx, 1 + math.abs(plus))
    damage = damage + (plus < 0 and -enchantment or enchantment)
    damage = damage + 1 + roll.melee(ctx, shot.natural_damage)
    potential = potential + shot.natural_damage
    local saved = roll.gdr_armour(ctx, defense, potential)
    outcome.damage = math.max(0, damage - saved)

    return outcome
end

-- Poison Dart shares contact rules with launched missiles but rolls its own damage on hit.
function ranged.poison_dart(ctx, hd, defense)
    local outcome = contact(ctx, hd, 0, 0, defense)

    if outcome.kind ~= "hit" then
        return outcome, 0
    end

    return outcome, 6 + roll.melee(ctx, 8)
end

return ranged
