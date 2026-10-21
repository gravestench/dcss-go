-- The branch contract names its required end layout. A different PLACE
-- file cannot keep the destination open after that layout is disabled.
local availability = require("policy.generation.floor_availability")
local branches = require("ids.branches")
local harness = require("tests.harness")
local layouts = require("policy.generation.layouts.catalog")

local test = {}

-- Check both the travel gate and direct catalog selection, since a mod or
-- another rule might ask the layout catalog without following a stair.
function test.run()
    harness.truthy(not availability.can_build(branches.BRANCH_ZOT, 5),
        "disabled effective Hall closes Zot:5")

    local random = {
        roll = function()
            return 0
        end,
    }
    local okay, reason = pcall(layouts.choose, random,
        branches.BRANCH_ZOT, 5, 5)

    harness.truthy(not okay and
        tostring(reason):find("missing required end layout", 1, true),
        "direct layout choice also rejects an impostor")
end

return test
