-- SPWPN_ACID splashes the player even after a zero-damage weapon contact.
-- Source: attack.cc::apply_damage_brand and player.cc::splash_with_acid.
local corrosion = require("policy.combat.player_corrosion")
local damage = require("policy.magic.damage")
local player_health = require("policy.combat.player_health")
local resistances = require("constants.resistance_ids")
local roll = require("policy.combat.roll")

local acid = {}

-- Player splashes roll 4d3, unlike the monster's 2d4. The corrosion owner
-- retains its independent source probability and resistance gate.
function acid.apply(ctx, hit)
    corrosion.apply(ctx, hit.defender, 3)

    local raw = 0

    for _ = 1, 4 do
        raw = raw + 1 + roll.melee(ctx, 3)
    end

    local bonus = damage.player_elemental(ctx, hit.defender,
        raw, resistances.ACID)

    hit.health = player_health.damage(ctx, hit.defender, bonus,
        false, hit.attacker)
    ctx:emit("combat", "You are splashed with acid!")
end

return acid
