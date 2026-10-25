-- Rugged Brown Scales use one scale selection and three scheduled ranks.
-- Source: mutation.cc:_demon_facets; the schedule owner chooses levels.
local categories = require("constants.catalog")
local facets = require("constants.demonspawn_facets")
local mutations = require("ids.mutations")

local definition = {
    id = "DS_FACET_RUGGED_BROWN_SCALES",
    tier = facets.SCALE,
    mutations = {
        mutations.MUT_RUGGED_BROWN_SCALES,
        mutations.MUT_RUGGED_BROWN_SCALES,
        mutations.MUT_RUGGED_BROWN_SCALES,
    },
    windows = {
        facets.EARLY,
        facets.EARLY,
        facets.ANY,
    },
}

register.definition(categories.DEMONSPAWN_FACETS, definition)

return definition
