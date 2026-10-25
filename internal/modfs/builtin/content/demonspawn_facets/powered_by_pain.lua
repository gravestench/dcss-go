-- Powered by Pain keeps the source's one-early timing.
-- Source: mutation.cc:_demon_facets; the schedule owner chooses levels.
local categories = require("constants.catalog")
local facets = require("constants.demonspawn_facets")
local mutations = require("ids.mutations")

local definition = {
    id = "DS_FACET_POWERED_BY_PAIN",
    tier = facets.SECONDARY,
    mutations = {
        mutations.MUT_POWERED_BY_PAIN,
        mutations.MUT_POWERED_BY_PAIN,
        mutations.MUT_POWERED_BY_PAIN,
    },
    windows = {
        facets.EARLY,
        facets.ANY,
        facets.ANY,
    },
}

register.definition(categories.DEMONSPAWN_FACETS, definition)

return definition
