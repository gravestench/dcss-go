-- Claws occupy the glove body slot; source places every rank early.
-- Source: mutation.cc:_demon_facets; the schedule owner chooses levels.
local categories = require("constants.catalog")
local facets = require("constants.demonspawn_facets")
local mutations = require("ids.mutations")
local slots = require("constants.armour_slots")

local definition = {
    id = "DS_FACET_CLAWS",
    tier = facets.BODY,
    mutations = {
        mutations.MUT_CLAWS,
        mutations.MUT_CLAWS,
        mutations.MUT_CLAWS,
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
