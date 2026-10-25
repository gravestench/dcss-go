-- Augmentation's three ranks are all placed in late windows.
-- Source: mutation.cc:_demon_facets; the schedule owner chooses levels.
local categories = require("constants.catalog")
local facets = require("constants.demonspawn_facets")
local mutations = require("ids.mutations")

local definition = {
    id = "DS_FACET_AUGMENTATION",
    tier = facets.FINAL,
    mutations = {
        mutations.MUT_AUGMENTATION,
        mutations.MUT_AUGMENTATION,
        mutations.MUT_AUGMENTATION,
    },
    windows = {
        facets.LATE,
        facets.LATE,
        facets.LATE,
    },
}

register.definition(categories.DEMONSPAWN_FACETS, definition)

return definition
