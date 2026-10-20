-- These four source layout.des maps complete its branch-only definitions.
-- The production catalog, terrain decoder, and stair postpass remain the
-- test entry points so fixture logic cannot become a second generator.
local branches = require("ids.branches")
local catalog = require("policy.generation.layouts.catalog")
local features = require("content.terrain_features")
local harness = require("tests.harness")
local weight = require("policy.generation.vaults.weight")

local test = {}

-- Use the production layout stream contract with a deterministic seed.
local function context_for(seed)
    local state = seed
    local context = {}

    function context:random_u64(stream)
        harness.equal(stream, "layout", "core layout stream")
        state = (state * 48271) % 2147483647
        local high = state

        state = (state * 48271) % 2147483647

        return high, state
    end

    return context
end

-- A branch layout must retain source weight and produce real traversable
-- terrain; registering a hook that leaves an empty rock grid is not enough.
local function execute(id, branch, local_depth, expected_weight, seed)
    local definition = catalog.get(id)
    local result = catalog.execute(context_for(seed),
        definition, branch, local_depth)
    local floor = 0

    harness.equal(weight.for_branch(definition, branch),
        expected_weight, id .. " source weight")
    harness.truthy(#result.stairs >= 3, id .. " connected stairs")
    harness.equal(#features.decode_source_rows(result.rows),
        70, id .. " terrain rows decode")

    for _, row in ipairs(result.rows) do
        for glyph in row:gmatch(".") do
            if glyph == "." then
                floor = floor + 1
            end
        end
    end

    harness.truthy(floor > 500, id .. " has source-sized open terrain")

    return result
end

-- The source branches exercise different corridor topology and cave
-- cleanup, including bottom-of-branch exits and minimum-area validation.
function test.run()
    local city = execute("layout_regular_city",
        branches.BRANCH_LAIR, 2, 15, 1001)

    harness.truthy(#city.rooms >= 10,
        "Regular City places many independent buildings")

    execute("layout_regular_city", branches.BRANCH_DIS, 2, 10, 1005)

    local corridors = execute("layout_misc_corridors",
        branches.BRANCH_ZOT, 2, 20, 1002)

    harness.truthy(corridors.corridor_count >= 10 and
        corridors.corridor_count <= 16,
        "Zot draws its shorter corridor chain")

    execute("layout_misc_corridors", branches.BRANCH_CRYPT, 1, 20, 1006)

    local caves = execute("layout_caves",
        branches.BRANCH_ORC, 2, 10, 1003)

    harness.equal(#caves.bubbles, 3,
        "Caves starts three source stair bubbles")

    execute("layout_caves", branches.BRANCH_ORC, 1, 10, 1007)
    execute("layout_caves", branches.BRANCH_SLIME, 1, 10, 1008)

    local mine = execute("layout_diamond_mine",
        branches.BRANCH_ORC, 1, 5, 1004)

    harness.truthy(mine.radius >= 4 and mine.radius <= 15,
        "Diamond Mine uses one source room radius")
    harness.truthy(mine.room_count > 0,
        "Diamond Mine places weighted lattice rooms")

    local bottom = catalog.execute(context_for(1010),
        catalog.get("layout_regular_city"), branches.BRANCH_LAIR, 5, {
            up = 3,
            down = 0,
        })

    for _, pair in ipairs(bottom.stairs) do
        harness.falsy(pair.down,
            "branch bottom must not invent a deeper stair")
    end
end

return test
