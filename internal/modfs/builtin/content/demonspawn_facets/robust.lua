-- Robust is a late facet; Ru must see it even before its first grant.
-- Source: mutation.cc:_demon_facets; the schedule owner chooses levels.
local categories = require("constants.catalog")
local facets = require("constants.demonspawn_facets")
local mutations = require("ids.mutations")

local definition = {
    id = "DS_FACET_ROBUST",
    tier = facets.FINAL,
    mutations = {
        mutations.MUT_ROBUST,
        mutations.MUT_ROBUST,
        mutations.MUT_ROBUST,
    },
    windows = {
        facets.LATE,
        facets.LATE,
        facets.LATE,
    },
}

register.definition(categories.DEMONSPAWN_FACETS, definition)

return definition
