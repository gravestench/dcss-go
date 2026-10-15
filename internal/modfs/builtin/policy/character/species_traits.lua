local names = require("constants.species_traits")

local species_traits = {}

function species_traits.stasis(species)
    for _, mutation in ipairs(species.fake_mutations or {}) do
        if mutation.short == names.STASIS then
            return true
        end
    end

    return false
end

return species_traits
