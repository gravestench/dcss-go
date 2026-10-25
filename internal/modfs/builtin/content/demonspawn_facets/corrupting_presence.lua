-- Corrupting Presence culminates in Word of Chaos as the third grant.
-- Source: mutation.cc:_demon_facets; the schedule owner chooses levels.
local categories = require("constants.catalog")
local facets = require("constants.demonspawn_facets")
local mutations = require("ids.mutations")

local definition = {
    id = "DS_FACET_CORRUPTING_PRESENCE",
    tier = facets.FINAL,
    mutations = {
        mutations.MUT_CORRUPTING_PRESENCE,
        mutations.MUT_CORRUPTING_PRESENCE,
        mutations.MUT_WORD_OF_CHAOS,
    },
    windows = {
        facets.LATE,
        facets.LATE,
        facets.LATE,
    },
}

register.definition(categories.DEMONSPAWN_FACETS, definition)

return definition
