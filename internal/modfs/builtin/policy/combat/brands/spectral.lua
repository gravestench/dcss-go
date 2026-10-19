-- Example: brand.apply() is inert for monster weapons; player spectral
-- weapons summon through monster_target_brands.spectral.after_attack(ctx, hit).
local brand = {}

-- Monster attacks create no spectral ally; the player attack lifecycle owns that effect.
function brand.apply()
end

return brand
