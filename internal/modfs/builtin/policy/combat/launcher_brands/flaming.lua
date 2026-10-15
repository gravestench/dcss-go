local elemental = require("policy.combat.launcher_brands.elemental")
local resistances = require("constants.resistance_ids")

local brand = {}

function brand.apply(ctx, missile, defender, damage)
    return elemental.apply(ctx, missile, defender, damage,
        resistances.FIRE, "burns")
end

return brand
