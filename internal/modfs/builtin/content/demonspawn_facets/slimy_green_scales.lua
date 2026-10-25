-- Slimy Green Scales are a scale facet despite their separate mutation effects.
-- Source: mutation.cc:_demon_facets; the schedule owner chooses levels.
local categories = require("constants.catalog")
local facets = require("constants.demonspawn_facets")
local mutations = require("ids.mutations")

local definition = {
    id = "DS_FACET_SLIMY_GREEN_SCALES",
    tier = facets.SCALE,
    mutations = {
        mutations.MUT_SLIMY_GREEN_SCALES,
        mutations.MUT_SLIMY_GREEN_SCALES,
        mutations.MUT_SLIMY_GREEN_SCALES,
    },
    windows = {
        facets.EARLY,
        facets.EARLY,
        facets.ANY,
    },
}

register.definition(categories.DEMONSPAWN_FACETS, definition)

return definition
