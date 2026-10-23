-- A new helper is discovered through the same effective VFS and tag
-- selector as bundled ruins. No central registry needs a new row.
local branches = require("ids.branches")
local harness = require("tests.harness")
local selection = require("policy.generation.vaults.selection")
local vaults = require("policy.generation.vaults.catalog")

local test = {}

-- The new map keeps its mod-authored weight and can be selected by tag.
function test.run()
    local map = vaults.get("my_salt_ruin")

    harness.equal(map.weight, 3, "new ruin keeps its source-style weight")
    harness.truthy(map.tags.desolation_ruin,
        "new ruin joins the shared ruin pool")

    local random = {}

    -- Force a valid draw while the production selector filters the overlay.
    function random:roll(bound)
        return bound - 1
    end

    local chosen = selection.choose_tag(random, "desolation_ruin", {
        branch_id = branches.BRANCH_DESOLATION,
        depth = 1,
        branch_bottom = 1,
        absolute_depth = 20,
        ignore_chance = true,
    })

    harness.truthy(chosen, "effective ruin pool is selectable")
end

return test
