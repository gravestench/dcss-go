-- Sharp Scales complete the source scale pool with two early ranks.
-- Source: mutation.cc:_demon_facets; the schedule owner chooses levels.
local categories = require("constants.catalog")
local facets = require("constants.demonspawn_facets")
local mutations = require("ids.mutations")

local definition = {
    id = "DS_FACET_SHARP_SCALES",
    tier = facets.SCALE,
    mutations = {
        mutations.MUT_SHARP_SCALES,
        mutations.MUT_SHARP_SCALES,
        mutations.MUT_SHARP_SCALES,
    },
    windows = {
        facets.EARLY,
        facets.EARLY,
        facets.ANY,
    },
}

register.definition(categories.DEMONSPAWN_FACETS, definition)

return definition
