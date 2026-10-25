-- A sparse mod can add one new body facet without copying the base tree.
-- It competes for gloves through the same source slot rule as Claws.
local categories = require("constants.catalog")
local facets = require("constants.demonspawn_facets")
local mutations = require("ids.mutations")
local slots = require("constants.armour_slots")

local definition = {
    id = "DS_FACET_TEST_CLAWS",
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
