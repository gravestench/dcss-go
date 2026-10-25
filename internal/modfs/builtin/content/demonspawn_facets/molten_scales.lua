-- Molten Scales belong to the scale pool, not the elemental exclusion group.
-- Source: mutation.cc:_demon_facets; the schedule owner chooses levels.
local categories = require("constants.catalog")
local facets = require("constants.demonspawn_facets")
local mutations = require("ids.mutations")

local definition = {
    id = "DS_FACET_MOLTEN_SCALES",
    tier = facets.SCALE,
    mutations = {
        mutations.MUT_MOLTEN_SCALES,
        mutations.MUT_MOLTEN_SCALES,
        mutations.MUT_MOLTEN_SCALES,
    },
    windows = {
        facets.EARLY,
        facets.EARLY,
        facets.ANY,
    },
}

register.definition(categories.DEMONSPAWN_FACETS, definition)

return definition
