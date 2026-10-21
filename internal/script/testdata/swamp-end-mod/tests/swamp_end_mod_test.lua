-- A sparse layered mod adds one weighted ending without replacing the base
-- family or changing the branch's Lua definition.
local branches = require("ids.branches")
local end_vault = require("policy.generation.vaults.end")
local harness = require("tests.harness")

local test = {}

-- The new NAME is last in stable sort order, so the final weighted bucket
-- proves it participates in the same source selection as built-in maps.
function test.run()
    local context = {
        branch_id = branches.BRANCH_SWAMP,
        depth = 4,
        branch_bottom = 4,
        absolute_depth = 18,
        end_vault_family = "swamp_end",
    }
    local candidates = end_vault.candidates(context)
    local random = {}

    function random:roll(bound)
        return bound - 1
    end

    local selected = end_vault.choose(random, candidates)

    harness.equal(#candidates, 12, "mod adds one Swamp end map")
    harness.equal(selected.id, "zz_reed_court",
        "new map joins the mandatory weighted pool")
end

return test
