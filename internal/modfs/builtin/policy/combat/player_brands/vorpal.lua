local roll = require("policy.combat.roll")

local brand = {
    requires_damage = true,
}

function brand.apply(ctx, hit, brands)
    -- Source: attack.cc:1423.
    local bonus = 1 + math.floor(roll.melee(ctx, hit.damage_done) / 3)
    brands.damage(ctx, hit, bonus)
end

return brand
