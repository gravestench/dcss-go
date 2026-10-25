-- Large Bone Plates grow as a scale facet, with the final rank placed later.
-- Source: mutation.cc:_demon_facets; the schedule owner chooses levels.
local categories = require("constants.catalog")
local facets = require("constants.demonspawn_facets")
local mutations = require("ids.mutations")

local definition = {
    id = "DS_FACET_LARGE_BONE_PLATES",
    tier = facets.SCALE,
    mutations = {
        mutations.MUT_LARGE_BONE_PLATES,
        mutations.MUT_LARGE_BONE_PLATES,
        mutations.MUT_LARGE_BONE_PLATES,
    },
    windows = {
        facets.EARLY,
        facets.EARLY,
        facets.ANY,
    },
}

register.definition(categories.DEMONSPAWN_FACETS, definition)

return definition
