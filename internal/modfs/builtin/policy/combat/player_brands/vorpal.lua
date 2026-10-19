local roll = require("policy.combat.roll")

local brand = {
    requires_damage = true,
}

-- Example: brand.apply(ctx, hit, brands) with positive base hit -> extra physical bonus damage
-- Vorpal deals an extra physical hit of one plus up to one third of ordinary damage.
function brand.apply(ctx, hit, brands)
    -- Source: attack.cc.
    local bonus = 1 + math.floor(roll.melee(ctx, hit.damage_done) / 3)
    brands.damage(ctx, hit, bonus)
end

return brand
