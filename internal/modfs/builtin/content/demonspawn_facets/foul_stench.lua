-- Foul Stench is cloud producing, so it cannot pair with Ignite Blood.
-- Source: mutation.cc:_demon_facets; the schedule owner chooses levels.
local categories = require("constants.catalog")
local facets = require("constants.demonspawn_facets")
local mutations = require("ids.mutations")

local definition = {
    id = "DS_FACET_FOUL_STENCH",
    tier = facets.SECONDARY,
    mutations = {
        mutations.MUT_FOUL_STENCH,
        mutations.MUT_FOUL_STENCH,
        mutations.MUT_FOUL_STENCH,
    },
    windows = {
        facets.EARLY,
        facets.ANY,
        facets.ANY,
    },
    cloud_producing = true,
}

register.definition(categories.DEMONSPAWN_FACETS, definition)

return definition
