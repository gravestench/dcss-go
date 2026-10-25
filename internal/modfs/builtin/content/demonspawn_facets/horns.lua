-- Horns occupy the helmet body slot and exclude Antennae.
-- Source: mutation.cc:_demon_facets; the schedule owner chooses levels.
local categories = require("constants.catalog")
local facets = require("constants.demonspawn_facets")
local mutations = require("ids.mutations")
local slots = require("constants.armour_slots")

local definition = {
    id = "DS_FACET_HORNS",
    tier = facets.BODY,
    mutations = {
        mutations.MUT_HORNS,
        mutations.MUT_HORNS,
        mutations.MUT_HORNS,
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
