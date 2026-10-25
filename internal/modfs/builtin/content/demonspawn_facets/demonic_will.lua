-- Demonic Will leads into Torment Resistance and Hurl Damnation late.
-- Source: mutation.cc:_demon_facets; the schedule owner chooses levels.
local categories = require("constants.catalog")
local facets = require("constants.demonspawn_facets")
local mutations = require("ids.mutations")

local definition = {
    id = "DS_FACET_DEMONIC_WILL",
    tier = facets.FINAL,
    mutations = {
        mutations.MUT_DEMONIC_WILL,
        mutations.MUT_TORMENT_RESISTANCE,
        mutations.MUT_HURL_DAMNATION,
    },
    windows = {
        facets.LATE,
        facets.LATE,
        facets.LATE,
    },
}

register.definition(categories.DEMONSPAWN_FACETS, definition)

return definition
