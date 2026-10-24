local roll = require("policy.combat.roll")
local player_health = require("policy.combat.player_health")
local damage = require("policy.magic.damage")
local resistances = require("constants.resistance_ids")

local brand = {
    after_death = true,
}

-- Example: brand.apply(ctx, hit) uses an independent electricity roll after
-- the weapon hit, even when that hit already killed the defender.
function brand.apply(ctx, hit)
    if damage.player_resistance(ctx, hit.defender,
        resistances.ELECTRICITY) > 0 then
        return
    end

    if roll.melee(ctx, 4) ~= 0 then
        return
    end

    local bonus = 8 + roll.melee(ctx, 13)
    hit.health = player_health.damage(ctx, hit.defender, bonus,
        false, hit.attacker)

    if bonus >= 18 then
        ctx:emit("combat", "You are electrocuted!!")
    else
        ctx:emit("combat", "You are electrocuted!")
    end
end

return brand
