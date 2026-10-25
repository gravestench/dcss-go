-- Icy Blue Scales use the scale timing shared by most source scale facets.
-- Source: mutation.cc:_demon_facets; the schedule owner chooses levels.
local categories = require("constants.catalog")
local facets = require("constants.demonspawn_facets")
local mutations = require("ids.mutations")

local definition = {
    id = "DS_FACET_ICY_BLUE_SCALES",
    tier = facets.SCALE,
    mutations = {
        mutations.MUT_ICY_BLUE_SCALES,
        mutations.MUT_ICY_BLUE_SCALES,
        mutations.MUT_ICY_BLUE_SCALES,
    },
    windows = {
        facets.EARLY,
        facets.EARLY,
        facets.ANY,
    },
}

register.definition(categories.DEMONSPAWN_FACETS, definition)

return definition
