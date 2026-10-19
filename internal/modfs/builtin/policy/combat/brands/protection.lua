-- Example: brand.apply() does no on-hit work; equipment.protection_ac(ctx,
-- monster) reads the +5 AC while the branded weapon remains equipped.
local brand = {}

-- Protection changes the attacker's defence elsewhere; there is no extra on-hit effect.
function brand.apply()
end

return brand
