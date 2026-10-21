-- One extra DES file in a layered mod joins the branch's mandatory end
-- pool without a Go case, a central ID list, or a second map registry.
local branches = require("ids.branches")
local end_vault = require("policy.generation.vaults.primary")
local harness = require("tests.harness")

local test = {}

-- The last cumulative bucket selects the new map after stable NAME sort.
function test.run()
    local context = {
        branch_id = branches.BRANCH_SNAKE,
        depth = 4,
        branch_bottom = 4,
        absolute_depth = 18,
        primary_vault_family = "snake_end",
    }
    local candidates = end_vault.candidates(context)
    local random = {}

    function random:roll(bound)
        return bound - 1
    end

    local selected = end_vault.choose(random, candidates)

    harness.equal(#candidates, 10, "mod adds one source-shaped end map")
    harness.equal(selected.id, "zz_shed", "new map joins weighted draw")
end

return test
