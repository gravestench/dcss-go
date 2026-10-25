-- Hex Enhancer, Black Mark, and Silence Aura share one final facet.
-- Source: mutation.cc:_demon_facets; the schedule owner chooses levels.
local categories = require("constants.catalog")
local facets = require("constants.demonspawn_facets")
local mutations = require("ids.mutations")

local definition = {
    id = "DS_FACET_HEX_ENHANCER",
    tier = facets.FINAL,
    mutations = {
        mutations.MUT_HEX_ENHANCER,
        mutations.MUT_BLACK_MARK,
        mutations.MUT_SILENCE_AURA,
    },
    windows = {
        facets.LATE,
        facets.LATE,
        facets.LATE,
    },
}

register.definition(categories.DEMONSPAWN_FACETS, definition)

return definition
