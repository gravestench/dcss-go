local roll = require("policy.combat.roll")

local brand = {}

-- Example: brand.apply(ctx, nil, nil, damage) with damage = 1 with zero melee draw -> 1 bonus damage
-- Vorpal adds damage proportional to the landed missile hit without another resistance type.
function brand.apply(ctx, _, _, damage)
    -- Source: attack.cc. This draw follows the ordinary hit roll.
    return 1 + math.floor(roll.melee(ctx, damage) / 3)
end

return brand
