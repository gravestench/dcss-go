-- A new effective DES path joins the Spider end pool in stable NAME order.
-- No branch edit or special Go loader path is needed for a sparse mod.
local branches = require("ids.branches")
local end_vault = require("policy.generation.vaults.primary")
local harness = require("tests.harness")

local test = {}

-- Draw the last bucket to prove the added map participates in selection.
function test.run()
    local context = {
        branch_id = branches.BRANCH_SPIDER,
        depth = 4,
        branch_bottom = 4,
        absolute_depth = 18,
        primary_vault_family = "spider_end",
    }
    local candidates = end_vault.candidates(context)
    local random = {}

    function random:roll(bound)
        return bound - 1
    end

    local selected = end_vault.choose(random, candidates)

    harness.equal(#candidates, 10, "mod adds one Spider end map")
    harness.equal(selected.id, "zz_silk_court",
        "new map joins the mandatory weighted pool")
end

return test
