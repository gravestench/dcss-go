-- Demonic Touch shares the glove body slot with Claws.
-- Source: mutation.cc:_demon_facets; the schedule owner chooses levels.
local categories = require("constants.catalog")
local facets = require("constants.demonspawn_facets")
local mutations = require("ids.mutations")
local slots = require("constants.armour_slots")

local definition = {
    id = "DS_FACET_DEMONIC_TOUCH",
    tier = facets.BODY,
    mutations = {
        mutations.MUT_DEMONIC_TOUCH,
        mutations.MUT_DEMONIC_TOUCH,
        mutations.MUT_DEMONIC_TOUCH,
    },
    windows = {
        facets.EARLY,
        facets.EARLY,
        facets.EARLY,
    },
    body_slot = slots.GLOVES,
}

register.definition(categories.DEMONSPAWN_FACETS, definition)

return definition
