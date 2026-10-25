-- The stinger occupies the cloak body slot in the source facet table.
-- Source: mutation.cc:_demon_facets; the schedule owner chooses levels.
local categories = require("constants.catalog")
local facets = require("constants.demonspawn_facets")
local mutations = require("ids.mutations")
local slots = require("constants.armour_slots")

local definition = {
    id = "DS_FACET_WEAKNESS_STINGER",
    tier = facets.BODY,
    mutations = {
        mutations.MUT_WEAKNESS_STINGER,
        mutations.MUT_WEAKNESS_STINGER,
        mutations.MUT_WEAKNESS_STINGER,
    },
    windows = {
        facets.EARLY,
        facets.EARLY,
        facets.EARLY,
    },
    body_slot = slots.CLOAK,
}

register.definition(categories.DEMONSPAWN_FACETS, definition)

return definition
