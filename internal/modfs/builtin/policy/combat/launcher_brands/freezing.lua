local elemental = require("policy.combat.launcher_brands.elemental")
local resistances = require("constants.resistance_ids")

local brand = {}

-- Example: brand.apply(ctx, missile, defender, damage) with cold-immune defender -> 0 cold bonus
-- A freezing launcher adds cold-resisted damage based on the missile hit.
function brand.apply(ctx, missile, defender, damage)
    return elemental.apply(ctx, missile, defender, damage,
        resistances.COLD, "freezes")
end

return brand
