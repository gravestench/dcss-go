-- Demonic Guardian's acquisition is scheduled separately from its summon policy.
-- Source: mutation.cc:_demon_facets; the schedule owner chooses levels.
local categories = require("constants.catalog")
local facets = require("constants.demonspawn_facets")
local mutations = require("ids.mutations")

local definition = {
    id = "DS_FACET_DEMONIC_GUARDIAN",
    tier = facets.SECONDARY,
    mutations = {
        mutations.MUT_DEMONIC_GUARDIAN,
        mutations.MUT_DEMONIC_GUARDIAN,
        mutations.MUT_DEMONIC_GUARDIAN,
    },
    windows = {
        facets.EARLY,
        facets.ANY,
        facets.ANY,
    },
}

register.definition(categories.DEMONSPAWN_FACETS, definition)

return definition
