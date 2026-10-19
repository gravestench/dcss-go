local accuracy = require("constants.beam_accuracy")
local monster_defense = require("policy.combat.monster_defense")
local roll = require("policy.combat.roll")

local defense = {}

-- Missile repulsion lowers beam accuracy using different draws for beams and projectiles.
local function repelled(ctx, snapshot, to_hit, profile)
    local reduced = to_hit

    if profile.can_beam then
        if to_hit >= 2 then
            local minimum = math.floor((to_hit + 1) / 2) + 1

            reduced = minimum + roll.spell(ctx,
                to_hit - minimum + 1)
        end
    else
        reduced = roll.spell(ctx, to_hit)
    end

    local attack = roll.spell(ctx, reduced)
    local evasion = roll.average_two(ctx, "monster_spell", snapshot.ev)

    return attack < evasion
end

-- Repeated shield blocks raise the bypass roll quadratically during the current combat state.
local function player_block(ctx, snapshot, to_hit)
    local bypass = math.floor(to_hit * 130 / 100) +
        5 * (snapshot.shield_blocks or 0) ^ 2
    local bypass_roll = roll.spell(ctx, bypass)
    local shield_roll = roll.average_two(ctx, "monster_spell",
        snapshot.shield_class * 2)
    local shield_bonus = math.floor(shield_roll / 3) - 1

    return bypass_roll < shield_bonus
end

-- Example: defense.roll(ctx, snapshot, to_hit, profile) with explosion profile -> no ordinary shield-block outcome
-- Resolve a single beam contact from the defender's current snapshot.
-- Piercing, explosions, and automatic-hit rays skip ordinary shield blocks.
function defense.roll(ctx, snapshot, to_hit, profile)
    local blockable = not profile.can_beam and
        not profile.is_explosion and
        to_hit ~= accuracy.AUTOMATIC_HIT

    if blockable and snapshot.monster_shield and
        monster_defense.beam_block(ctx, snapshot.monster_shield,
            to_hit) then
        return {
            kind = snapshot.reflects and "reflect" or "block",
        }
    end

    if blockable and not snapshot.monster_shield and
        (snapshot.shield_class or 0) > 0 and
        player_block(ctx, snapshot, to_hit) then
        return {
            kind = snapshot.reflects and "reflect" or "block",
        }
    end

    if to_hit == accuracy.AUTOMATIC_HIT or profile.is_explosion then
        return { kind = "hit" }
    end

    local attack = roll.spell(ctx, to_hit)
    local evasion = roll.average_two(ctx, "monster_spell", snapshot.ev)

    if attack < evasion then
        return { kind = "miss" }
    end

    if snapshot.missile_repulsion and
        repelled(ctx, snapshot, to_hit, profile) then
        return { kind = "repel" }
    end

    return { kind = "hit" }
end

return defense
