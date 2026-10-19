-- Example: Formicid stasis is found in species mutations when checking teleport restrictions.
local names = require("constants.species_traits")

local species_traits = {}

-- Formicid stasis is represented as a fake species mutation, so item rules must inspect that list.
function species_traits.stasis(species)
    for _, mutation in ipairs(species.fake_mutations or {}) do
        if mutation.short == names.STASIS then
            return true
        end
    end

    return false
end

return species_traits
