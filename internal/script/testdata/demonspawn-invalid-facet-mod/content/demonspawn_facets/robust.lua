-- A layered mod can replace a source facet. This deliberately invalid
-- replacement requests three ranks of a one-rank mutation, so creation
-- must reject it before any future trait enters a save.
local categories = require("constants.catalog")
local facets = require("constants.demonspawn_facets")
local mutations = require("ids.mutations")

local definition = {
    id = "DS_FACET_ROBUST",
    tier = facets.FINAL,
    mutations = {
        mutations.MUT_CONDENSATION_SHIELD,
        mutations.MUT_CONDENSATION_SHIELD,
        mutations.MUT_CONDENSATION_SHIELD,
    },
    windows = {
        facets.LATE,
        facets.LATE,
        facets.LATE,
    },
}

register.definition(categories.DEMONSPAWN_FACETS, definition)

return definition
