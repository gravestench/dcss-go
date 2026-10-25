-- Replacing the base file by relative path changes one facet definition
-- while every unrelated Demonspawn facet remains embedded and available.
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
        facets.ANY,
        facets.ANY,
        facets.ANY,
    },
}

register.definition(categories.DEMONSPAWN_FACETS, definition)

return definition
