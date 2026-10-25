-- Sanguine Armour is selected with scales; its effect remains in its own policy.
-- Source: mutation.cc:_demon_facets; the schedule owner chooses levels.
local categories = require("constants.catalog")
local facets = require("constants.demonspawn_facets")
local mutations = require("ids.mutations")

local definition = {
    id = "DS_FACET_SANGUINE_ARMOUR",
    tier = facets.SCALE,
    mutations = {
        mutations.MUT_SANGUINE_ARMOUR,
        mutations.MUT_SANGUINE_ARMOUR,
        mutations.MUT_SANGUINE_ARMOUR,
    },
    windows = {
        facets.EARLY,
        facets.EARLY,
        facets.ANY,
    },
}

register.definition(categories.DEMONSPAWN_FACETS, definition)

return definition
