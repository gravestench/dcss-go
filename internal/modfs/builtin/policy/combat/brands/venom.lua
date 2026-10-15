local roll = require("policy.combat.roll")

local brand = {}

function brand.apply(ctx, hit, brands)
    if roll.melee(ctx, 4) == 0 then
        return
    end

    local base = roll.melee(ctx, 8)
    local bonus = roll.melee(ctx, math.floor(hit.damage_done * 3 / 2))

    brands.poison(ctx, 6 + base + bonus, hit.source_id)
end

return brand
