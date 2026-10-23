-- Every source destination must generate through the ordinary staged-floor
-- owner. This catches a map that parses but cannot create a return route.
local branches = require("ids.branches")
local harness = require("tests.harness")
local terrain = require("constants.terrain")

local test = {}

-- A repeatable stream keeps the failing source NAME visible in test output.
local function random_context()
    local state = 83
    local context = {}

    -- Grid placement consumes both halves of a random generation draw.
    function context:random_u64()
        state = (state * 48271) % 2147483647
        local high = state
        state = (state * 48271) % 2147483647

        return high, state
    end

    -- Hooks and the weighted selector consume bounded draws.
    function context:random(_, bound)
        state = (state * 48271) % 2147483647

        return state % bound
    end

    return context
end

-- Count all authored arches. Some maps intentionally offer several paths
-- back to the same exact outside gate, so one arrival anchor is insufficient.
local function exits(cells)
    local count = 0

    for _, row in ipairs(cells) do
        for _, feature in ipairs(row) do
            if feature == terrain.DNGN_EXIT_VOLCANO then
                count = count + 1
            end
        end
    end

    return count
end

-- Candidate order follows stable source IDs and excludes tagged helpers.
-- Each positive-weight choice must produce a live floor with a safe exit.
function test.run()
    local level = require("policy.generation.volcano.level")
    local maps = level.candidates({})
    local prior = ""

    harness.equal(#maps, 14, "top-level Volcano map count")

    for _, map in ipairs(maps) do
        harness.truthy(map.id > prior, "Volcano candidate ID order")
        harness.truthy(map.weight > 0, map.id .. " has zero weight")

        local floor = level.generate(random_context(), {
            layout_id = map.id,
            species_id = "SP_HUMAN",
            player_name = "Tester",
        }).level

        harness.equal(floor.branch_id, branches.BRANCH_VOLCANO,
            map.id .. " branch")
        harness.equal(floor.vault_id, map.id, map.id .. " source map")
        harness.truthy(exits(floor.cells) > 0,
            map.id .. " has no return arch")
        harness.equal(floor.cells[floor.entry_y + 1]
            [floor.entry_x + 1], terrain.DNGN_EXIT_VOLCANO,
            map.id .. " arrival anchor")
        harness.truthy(#floor.vault_records > 0,
            map.id .. " has no typed records")
        prior = map.id
    end
end

return test
