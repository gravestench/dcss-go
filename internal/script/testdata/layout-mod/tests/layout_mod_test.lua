-- Exercise both a replacement .des path and a newly added layout using the
-- same layered VFS and catalog that an ordinary game loads at startup.
local branches = require("ids.branches")
local catalog = require("policy.generation.layouts.catalog")
local weight = require("policy.generation.vaults.weight")
local harness = require("tests.harness")

local test = {}

-- The overlay wins its relative path; the added definition is independent.
-- Neither action requires an edit to the bundled layout selector.
function test.run()
    harness.equal(#catalog.ids(), 41, "mod adds one effective layout")
    harness.equal(weight.for_branch(catalog.get("layout_basic"),
        branches.BRANCH_DUNGEON), 0, "mod disables basic")
    harness.equal(weight.for_branch(catalog.get("layout_modded"),
        branches.BRANCH_DUNGEON), 100, "mod adds weighted layout")

    local found = false

    for draw = 0, 400 do
        local random = {}

        function random:roll(bound)
            return draw % bound
        end

        local selected = catalog.choose(random,
            branches.BRANCH_DUNGEON, 1, 15)

        harness.falsy(selected.id == "layout_basic",
            "disabled base layout is never selected")
        found = found or selected.id == "layout_modded"
    end

    harness.truthy(found, "new layout participates in weighted choice")
end

return test
