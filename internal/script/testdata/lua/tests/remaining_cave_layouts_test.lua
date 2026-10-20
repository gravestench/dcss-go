-- Falls Marsh and Cave Town are the final two source layout_caves.des
-- definitions. Exercise their branch clauses and actual Lua geometry.
local branches = require("ids.branches")
local catalog = require("policy.generation.layouts.catalog")
local depth = require("policy.generation.vaults.depth")
local harness = require("tests.harness")
local weight = require("policy.generation.vaults.weight")

local test = {}

-- Use the same bounded layout RNG contract as the game kernel.
local function context_for(seed)
    local state = seed
    local context = {}

    function context:random_u64(stream)
        harness.equal(stream, "layout", "last cave layout stream")
        state = (state * 1664525 + 1013904223) % 4294967296

        return state, (state * 22695477 + 1) % 4294967296
    end

    return context
end

-- Source Swamp excludes its rune floor. Every tested branch depth still
-- needs a navigable marsh with both kinds of water and pooled terrain.
local function marsh()
    local definition = catalog.get("layout_falls_marsh")
    local water = 0
    local trees = 0

    harness.equal(weight.for_branch(definition,
        branches.BRANCH_SWAMP), 10, "Falls Marsh weight")
    harness.falsy(depth.eligible(definition,
        branches.BRANCH_SWAMP, 4, 4),
        "Falls Marsh skips the Swamp rune floor")

    for level = 1, 3 do
        local result = catalog.execute(context_for(level * 197),
            definition, branches.BRANCH_SWAMP, level)

        harness.truthy(#result.stairs >= 3,
            "Falls Marsh has connected stair pairs")
        harness.truthy(result.pool_count > 0,
            "Falls Marsh grows source pools")

        for _, row in ipairs(result.rows) do
            for glyph in row:gmatch(".") do
                if glyph == "W" then
                    water = water + 1
                elseif glyph == "t" then
                    trees = trees + 1
                end
            end
        end
    end

    harness.truthy(water > 100,
        "Falls Marsh retains shallow water")
    harness.truthy(trees > 100,
        "Falls Marsh retains its surrounding tree terrain")
end

-- Snake Cave Town uses one selected room painter throughout each level.
-- Its deeper source weights rise sharply toward the branch bottom.
local function town()
    local definition = catalog.get("layout_cave_town")
    local expected = { 5, 15, 50 }
    local huts = 0

    harness.falsy(depth.eligible(definition,
        branches.BRANCH_SNAKE, 1, 4),
        "Cave Town begins at Snake:2")

    for local_depth = 2, 4 do
        harness.equal(weight.for_branch(definition,
            branches.BRANCH_SNAKE, local_depth, 4),
            expected[local_depth - 1],
            "Cave Town depth weight")

        local result = catalog.execute(context_for(local_depth * 211),
            definition, branches.BRANCH_SNAKE, local_depth)

        harness.truthy(#result.stairs >= 3,
            "Cave Town has connected stair pairs")
        harness.truthy(result.room_count > 0,
            "Cave Town places source cave rooms")
        huts = huts + result.room_count
    end

    harness.truthy(huts >= 10,
        "Cave Town retains its multi-room source design")
end

-- Both maps remain branch-only and discoverable from committed DES files.
function test.run()
    marsh()
    town()
end

return test
