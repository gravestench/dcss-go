-- The branch-entry selector reads the effective layered catalog, so a mod
-- can add a new gate without changing bundled lists or Go branch code.
local branches = require("ids.branches")
local entry = require("policy.generation.vaults.branch_entry")
local harness = require("tests.harness")

local test = {}

-- A bottom-of-Dungeon weight joins the pool, while an unrelated PLACE map
-- cannot be selected for the scheduled Depths entrance.
function test.run()
    local floor = {
        branch_id = branches.BRANCH_DUNGEON,
        depth = 15,
        branch_bottom = 15,
        absolute_depth = 15,
    }
    local choices = entry.candidates(branches.BRANCH_DEPTHS, floor)
    local found = false

    harness.equal(#choices, 9, "Depths entry mod candidate count")

    for _, choice in ipairs(choices) do
        if choice.definition.id == "modded_depths_gate" then
            harness.equal(choice.weight, 7,
                "modded Depths gate weight")
            found = true
        end
    end

    harness.truthy(found, "modded Depths gate is selectable")
end

return test
