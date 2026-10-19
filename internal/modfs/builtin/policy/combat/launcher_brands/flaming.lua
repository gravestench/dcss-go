local elemental = require("policy.combat.launcher_brands.elemental")
local resistances = require("constants.resistance_ids")

local brand = {}

-- Example: brand.apply(ctx, missile, defender, damage) with fire-immune defender -> 0 fire bonus
-- A flaming launcher adds a fire-resisted bonus only to a damaging missile.
function brand.apply(ctx, missile, defender, damage)
    return elemental.apply(ctx, missile, defender, damage,
        resistances.FIRE, "burns")
end

return brand
