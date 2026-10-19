-- Example: brand.apply() is inert for monster weapons; player spectral
-- weapons summon through player_brands.spectral.after_attack(ctx, hit).
local brand = {}

-- Monster attacks create no spectral ally; the player attack lifecycle owns that effect.
function brand.apply()
end

return brand
