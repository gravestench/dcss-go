-- Explicit PLACE has precedence on its floor, while other floors keep their
-- ordinary weighted layout pool. The fixture overlays a real DES file, so
-- this exercises the production parser and selector together.
local branches = require("ids.branches")
local catalog = require("policy.generation.layouts.catalog")
local harness = require("tests.harness")

local test = {}

-- Return a valid bounded draw regardless of which pool is being selected.
local function picker()
    local random = {}

    function random:roll()
        return 0
    end

    return random
end

-- A matching PLACE map wins V:5 even though the branch has weighted maps.
-- It must not leak into the ordinary V:4 draw.
function test.run()
    local end_map = catalog.choose(picker(), branches.BRANCH_VAULTS, 5, 5)
    local ordinary = catalog.choose(picker(), branches.BRANCH_VAULTS, 4, 5)

    harness.equal(end_map.id, "test_explicit_bottom", "PLACE precedence")
    harness.truthy(ordinary.id ~= "test_explicit_bottom",
        "PLACE map is absent from ordinary pool")
end

return test
