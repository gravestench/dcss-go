-- The pinned source has six body, thirteen scale, nine tier-two, and five
-- tier-three Demonspawn facets. Every one must be discoverable as content.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local harness = require("tests.harness")
local mutations = require("ids.mutations")

local test = {}

-- Check the effective production catalog rather than repeat definitions in
-- the fixture. This catches absent files and broken mutation references.
function test.run()
    local definitions = catalog.all(categories.DEMONSPAWN_FACETS)
    local tiers = {
        [0] = 0,
        [1] = 0,
        [2] = 0,
        [3] = 0,
    }
    local robust = false

    harness.equal(#definitions, 33)

    for _, facet in ipairs(definitions) do
        tiers[facet.tier] = tiers[facet.tier] + 1
        harness.equal(#facet.mutations, 3)
        harness.equal(#facet.windows, 3)

        for _, id in ipairs(facet.mutations) do
            harness.equal(catalog.get(categories.MUTATIONS, id).status,
                "active")

            if id == mutations.MUT_ROBUST then
                robust = true
            end
        end
    end

    harness.equal(tiers[0], 6)
    harness.equal(tiers[1], 13)
    harness.equal(tiers[2], 9)
    harness.equal(tiers[3], 5)
    harness.truthy(robust, "Robust future facet is missing")

end

return test
