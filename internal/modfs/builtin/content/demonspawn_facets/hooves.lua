-- Hooves occupy the boot body slot; each rank keeps its early window.
-- Source: mutation.cc:_demon_facets; the schedule owner chooses levels.
local categories = require("constants.catalog")
local facets = require("constants.demonspawn_facets")
local mutations = require("ids.mutations")
local slots = require("constants.armour_slots")

local definition = {
    id = "DS_FACET_HOOVES",
    tier = facets.BODY,
    mutations = {
        mutations.MUT_HOOVES,
        mutations.MUT_HOOVES,
        mutations.MUT_HOOVES,
    },
    windows = {
        facets.EARLY,
        facets.EARLY,
        facets.EARLY,
    },
    body_slot = slots.BOOTS,
}

register.definition(categories.DEMONSPAWN_FACETS, definition)

return definition
