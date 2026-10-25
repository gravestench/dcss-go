-- Spiny supplies three ordered secondary grants.
-- Source: mutation.cc:_demon_facets; the schedule owner chooses levels.
local categories = require("constants.catalog")
local facets = require("constants.demonspawn_facets")
local mutations = require("ids.mutations")

local definition = {
    id = "DS_FACET_SPINY",
    tier = facets.SECONDARY,
    mutations = {
        mutations.MUT_SPINY,
        mutations.MUT_SPINY,
        mutations.MUT_SPINY,
    },
    windows = {
        facets.EARLY,
        facets.ANY,
        facets.ANY,
    },
}

register.definition(categories.DEMONSPAWN_FACETS, definition)

return definition
