-- Big Brain is a scale-tier facet in source selection, not a body slot.
-- Source: mutation.cc:_demon_facets; the schedule owner chooses levels.
local categories = require("constants.catalog")
local facets = require("constants.demonspawn_facets")
local mutations = require("ids.mutations")

local definition = {
    id = "DS_FACET_BIG_BRAIN",
    tier = facets.SCALE,
    mutations = {
        mutations.MUT_BIG_BRAIN,
        mutations.MUT_BIG_BRAIN,
        mutations.MUT_BIG_BRAIN,
    },
    windows = {
        facets.EARLY,
        facets.EARLY,
        facets.ANY,
    },
}

register.definition(categories.DEMONSPAWN_FACETS, definition)

return definition
