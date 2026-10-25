-- Thin Skeletal Structure is selected from the scale pool in the source.
-- Source: mutation.cc:_demon_facets; the schedule owner chooses levels.
local categories = require("constants.catalog")
local facets = require("constants.demonspawn_facets")
local mutations = require("ids.mutations")

local definition = {
    id = "DS_FACET_THIN_SKELETAL_STRUCTURE",
    tier = facets.SCALE,
    mutations = {
        mutations.MUT_THIN_SKELETAL_STRUCTURE,
        mutations.MUT_THIN_SKELETAL_STRUCTURE,
        mutations.MUT_THIN_SKELETAL_STRUCTURE,
    },
    windows = {
        facets.EARLY,
        facets.EARLY,
        facets.ANY,
    },
}

register.definition(categories.DEMONSPAWN_FACETS, definition)

return definition
