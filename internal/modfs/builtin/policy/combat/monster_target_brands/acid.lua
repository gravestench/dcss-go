-- SPWPN_ACID splashes a monster after contact, regardless of ordinary
-- weapon damage. Source: attack.cc::apply_damage_brand and
-- monster.cc::monster::splash_with_acid.
local damage = require("policy.magic.damage")
local enchant = require("policy.combat.monster_enchant")
local resistances = require("constants.resistance_ids")
local roll = require("policy.combat.roll")

local acid = {}

-- Full acid immunity prevents both splash damage and corrosion. Below that
-- threshold the independent 2d4 splash and 2/3 corrosion roll still run.
function acid.apply(ctx, hit, brands)
    if damage.monster_resistance(ctx, hit.defender,
        resistances.ACID) >= 3 then
        return
    end

    local raw = 2 + roll.melee(ctx, 4) + roll.melee(ctx, 4)
    local bonus = damage.monster_elemental(ctx, hit.defender,
        raw, resistances.ACID)

    enchant.corrode(ctx, hit.defender, hit.definition)
    brands.damage(ctx, hit, bonus)
    ctx:emit("combat", "The " .. hit.definition.name ..
        " is splashed with acid.")
end

return acid
