-- Demonic Magic uses one early rank and two unrestricted ranks.
-- Source: mutation.cc:_demon_facets; the schedule owner chooses levels.
local categories = require("constants.catalog")
local facets = require("constants.demonspawn_facets")
local mutations = require("ids.mutations")

local definition = {
    id = "DS_FACET_DEMONIC_MAGIC",
    tier = facets.SECONDARY,
    mutations = {
        mutations.MUT_DEMONIC_MAGIC,
        mutations.MUT_DEMONIC_MAGIC,
        mutations.MUT_DEMONIC_MAGIC,
    },
    windows = {
        facets.EARLY,
        facets.ANY,
        facets.ANY,
    },
}

register.definition(categories.DEMONSPAWN_FACETS, definition)

return definition
