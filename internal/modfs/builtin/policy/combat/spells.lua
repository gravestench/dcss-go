local roll = require("policy.combat.roll")
local monster_defense = require("policy.combat.monster_defense")

local spells = {}

function spells.freeze(ctx, hd)
    local sides = 3 + math.floor(6 * hd / 3)

    -- Freeze bypasses AC and EV, then rolls its one damage die.
    return 1 + ctx:random("monster_spell", sides)
end

function spells.slug_dart(ctx, hd, defense)
    local power = 12 * hd
    local to_hit = 14 + math.floor(power / 35)
    local die_sides = 3 + math.floor(power / 25)

    if defense.monster_shield then
        if monster_defense.beam_block(ctx, defense.monster_shield,
            to_hit) then
            return {
                kind = "block",
                damage = 0,
                shield_blocks = defense.shield_blocks + 1,
            }
        end
    elseif defense.shield_class > 0 then
        local bypass = math.floor(to_hit * 130 / 100) + 5 * defense.shield_blocks ^ 2
        local bypass_roll = roll.spell(ctx, bypass)
        local shield_roll = roll.average_two(ctx, "monster_spell", defense.shield_class * 2)
        local shield_bonus = math.floor(shield_roll / 3) - 1

        if bypass_roll < shield_bonus then
            return { kind = "block", damage = 0, shield_blocks = defense.shield_blocks + 1 }
        end
    end

    local attack_roll = roll.spell(ctx, to_hit)
    local evasion_roll = roll.average_two(ctx, "monster_spell", defense.ev)

    if attack_roll < evasion_roll then
        return { kind = "miss", damage = 0, shield_blocks = defense.shield_blocks }
    end

    local first = roll.spell(ctx, die_sides)
    local second = roll.spell(ctx, die_sides)
    local armour = roll.spell(ctx, defense.ac + 1)

    return {
        kind = "hit",
        damage = math.max(0, 2 + first + second - armour),
        shield_blocks = defense.shield_blocks,
    }
end

return spells
