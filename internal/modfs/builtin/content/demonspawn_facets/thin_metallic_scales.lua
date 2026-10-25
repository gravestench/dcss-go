-- Thin Metallic Scales retain the source's two-early, one-any timing.
-- Source: mutation.cc:_demon_facets; the schedule owner chooses levels.
local categories = require("constants.catalog")
local facets = require("constants.demonspawn_facets")
local mutations = require("ids.mutations")

local definition = {
    id = "DS_FACET_THIN_METALLIC_SCALES",
    tier = facets.SCALE,
    mutations = {
        mutations.MUT_THIN_METALLIC_SCALES,
        mutations.MUT_THIN_METALLIC_SCALES,
        mutations.MUT_THIN_METALLIC_SCALES,
    },
    windows = {
        facets.EARLY,
        facets.EARLY,
        facets.ANY,
    },
}

register.definition(categories.DEMONSPAWN_FACETS, definition)

return definition
