local roll = require("policy.combat.roll")

local brand = {}

function brand.apply(ctx, _, _, damage)
    -- Source: attack.cc:1423. This draw follows the ordinary hit roll.
    return 1 + math.floor(roll.melee(ctx, damage) / 3)
end

return brand
