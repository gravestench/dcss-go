local brand = {}

-- Example: brand.apply() with unbranded launcher -> 0 bonus
-- Unbranded launchers resolve through an explicit zero-bonus effect.
function brand.apply()
    return 0
end

return brand
