-- Condensation Shield leads into two Icemail ranks and is elemental.
-- Source: mutation.cc:_demon_facets; the schedule owner chooses levels.
local categories = require("constants.catalog")
local facets = require("constants.demonspawn_facets")
local mutations = require("ids.mutations")

local definition = {
    id = "DS_FACET_CONDENSATION_SHIELD",
    tier = facets.SECONDARY,
    mutations = {
        mutations.MUT_CONDENSATION_SHIELD,
        mutations.MUT_ICEMAIL,
        mutations.MUT_ICEMAIL,
    },
    windows = {
        facets.EARLY,
        facets.ANY,
        facets.ANY,
    },
    elemental = true,
}

register.definition(categories.DEMONSPAWN_FACETS, definition)

return definition
