-- Selection is forced to the octagon arrival so placement can be checked deterministically.

local vaults = require("ids.vaults")

local selection = {}

-- Force one named arrival through the normal catalog lookup. This removes RNG
-- from the fixture while still exercising real vault placement and terrain.
-- Example: require("policy.generation.vaults.selection").choose_catalog().
function selection.choose_catalog()
    return {
        id = vaults.enne_arrival_octagon_isle,
    }
end

-- This fixture isolates the forced arrival. The live generator now may
-- request a supplemental map, so explicitly decline that separate draw.
function selection.choose_tag()
    return nil
end

return selection
