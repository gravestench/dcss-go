-- Example: brand.apply() leaves the current living player roster unchanged;
-- holy susceptibility is validated for future species separately.
local brand = {}

-- This roster has no valid monster Holy Wrath target; eligibility is checked by the brand policy.
function brand.apply()
end

return brand
