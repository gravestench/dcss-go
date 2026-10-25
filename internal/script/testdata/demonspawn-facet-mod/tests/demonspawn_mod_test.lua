-- The effective catalog includes a new facet and a path-overridden one;
-- neither requires a Go registry edit or a duplicate base mod directory.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local facets = require("constants.demonspawn_facets")
local harness = require("tests.harness")
local ids = require("ids.demonspawn_facets")

local test = {}

-- Read the same effective definitions the character creation owner sees.
function test.run()
    local definitions = catalog.all(categories.DEMONSPAWN_FACETS)
    local robust = catalog.get(categories.DEMONSPAWN_FACETS,
        ids.DS_FACET_ROBUST)

    harness.equal(#definitions, 34)
    harness.equal(robust.windows[1], facets.ANY)
    harness.truthy(catalog.get(categories.DEMONSPAWN_FACETS,
        ids.DS_FACET_TEST_CLAWS))
end

return test
