-- Antennae share the helmet body slot with Horns.
-- Source: mutation.cc:_demon_facets; the schedule owner chooses levels.
local categories = require("constants.catalog")
local facets = require("constants.demonspawn_facets")
local mutations = require("ids.mutations")
local slots = require("constants.armour_slots")

local definition = {
    id = "DS_FACET_ANTENNAE",
    tier = facets.BODY,
    mutations = {
        mutations.MUT_ANTENNAE,
        mutations.MUT_ANTENNAE,
        mutations.MUT_ANTENNAE,
    },
    windows = {
        facets.EARLY,
        facets.EARLY,
        facets.EARLY,
    },
    body_slot = slots.HELMET,
}

register.definition(categories.DEMONSPAWN_FACETS, definition)

return definition
