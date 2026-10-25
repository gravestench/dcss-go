-- Branch floor IDs and permanent special regions share one saved level map.
-- An overlap can strand a pending stair before the target branch is entered.
local abyss = require("constants.abyss")
local branches = require("policy.generation.branch_levels")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local harness = require("tests.harness")

local test = {}

-- Enumerate the effective branch catalog, including layered mods, rather
-- than pinning only the built-in Slime collision that exposed this bug.
function test.run()
    local used = {
        [abyss.LEVEL_ID] = "Abyss window",
        [abyss.TRANSIT_LEVEL_ID] = "Abyss transit",
    }

    harness.truthy(abyss.LEVEL_ID ~= abyss.TRANSIT_LEVEL_ID,
        "the two Abyss regions need distinct IDs")

    for _, branch in ipairs(catalog.all(categories.BRANCHES)) do
        for depth = 1, branch.depth do
            local id = branches.id(branch.id, depth)

            harness.falsy(used[id],
                branch.id .. ":" .. depth .. " collides with " ..
                    tostring(used[id]))
            used[id] = branch.id .. ":" .. depth
        end
    end
end

return test
