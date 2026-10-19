-- Protection changes AC while wielded; it has no on-hit effect.
local brand = {
    after_death = true,
}

-- Example: brand.apply() with worn Protection weapon -> no on-hit effect; AC comes from gear
-- Protection modifies wielder AC through equipment and has no on-hit branch.
function brand.apply()
end

return brand
