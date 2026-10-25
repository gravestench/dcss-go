-- Ignite Blood counts as both elemental and cloud producing during rerolls.
-- Source: mutation.cc:_demon_facets; the schedule owner chooses levels.
local categories = require("constants.catalog")
local facets = require("constants.demonspawn_facets")
local mutations = require("ids.mutations")

local definition = {
    id = "DS_FACET_IGNITE_BLOOD",
    tier = facets.SECONDARY,
    mutations = {
        mutations.MUT_IGNITE_BLOOD,
        mutations.MUT_IGNITE_BLOOD,
        mutations.MUT_IGNITE_BLOOD,
    },
    windows = {
        facets.EARLY,
        facets.ANY,
        facets.ANY,
    },
    elemental = true,
    cloud_producing = true,
}

register.definition(categories.DEMONSPAWN_FACETS, definition)

return definition
