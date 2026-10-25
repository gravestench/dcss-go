-- Mana Regeneration, Shield, and Link form one ordered source facet.
-- Source: mutation.cc:_demon_facets; the schedule owner chooses levels.
local categories = require("constants.catalog")
local facets = require("constants.demonspawn_facets")
local mutations = require("ids.mutations")

local definition = {
    id = "DS_FACET_MANA_REGENERATION",
    tier = facets.SECONDARY,
    mutations = {
        mutations.MUT_MANA_REGENERATION,
        mutations.MUT_MANA_SHIELD,
        mutations.MUT_MANA_LINK,
    },
    windows = {
        facets.EARLY,
        facets.ANY,
        facets.ANY,
    },
}

register.definition(categories.DEMONSPAWN_FACETS, definition)

return definition
