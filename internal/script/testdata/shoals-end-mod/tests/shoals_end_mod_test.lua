-- A new effective DES path joins Shoals' mandatory end pool in stable
-- NAME order. A mod need not edit the branch or any Go registration table.
local branches = require("ids.branches")
local end_vault = require("policy.generation.vaults.end")
local harness = require("tests.harness")

local test = {}

-- Draw the last weight bucket to prove the sparse mod is selectable.
function test.run()
    local context = {
        branch_id = branches.BRANCH_SHOALS,
        depth = 4,
        branch_bottom = 4,
        absolute_depth = 18,
        end_vault_family = "shoals_end",
    }
    local candidates = end_vault.candidates(context)
    local random = {}

    function random:roll(bound)
        return bound - 1
    end

    local selected = end_vault.choose(random, candidates)

    harness.equal(#candidates, 7, "mod adds one Shoals finale")
    harness.equal(selected.id, "zz_tide_court",
        "new map joins the weighted end pool")
end

return test
