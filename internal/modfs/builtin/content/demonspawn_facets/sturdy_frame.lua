-- Sturdy Frame follows the scale facet schedule despite its defensive effect.
-- Source: mutation.cc:_demon_facets; the schedule owner chooses levels.
local categories = require("constants.catalog")
local facets = require("constants.demonspawn_facets")
local mutations = require("ids.mutations")

local definition = {
    id = "DS_FACET_STURDY_FRAME",
    tier = facets.SCALE,
    mutations = {
        mutations.MUT_STURDY_FRAME,
        mutations.MUT_STURDY_FRAME,
        mutations.MUT_STURDY_FRAME,
    },
    windows = {
        facets.EARLY,
        facets.EARLY,
        facets.ANY,
    },
}

register.definition(categories.DEMONSPAWN_FACETS, definition)

return definition
