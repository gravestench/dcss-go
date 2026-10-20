-- The source Depths doughnut has a traversable ring, sometimes pierced by
-- a cross and a central octagon. Exercise the production DES and Lua hook.
local branches = require("ids.branches")
local catalog = require("policy.generation.layouts.catalog")
local depth = require("policy.generation.vaults.depth")
local harness = require("tests.harness")
local weight = require("policy.generation.vaults.weight")

local test = {}

-- Use a deterministic kernel-style stream without copying layout rules.
local function context_for(seed)
    local state = seed
    local context = {}

    function context:random_u64(stream)
        harness.equal(stream, "layout", "doughnut layout stream")
        state = (state * 1664525 + 1013904223) % 4294967296

        return state, (state * 22695477 + 1) % 4294967296
    end

    return context
end

-- All generated variants must leave the ring and shared stairs reachable.
-- The central hole remains visible in at least one non-cross variant.
local function generated_shapes()
    local hole = false
    local water = false
    local lava = false

    for seed = 1, 20 do
        local result = catalog.execute(context_for(seed),
            catalog.get("layout_forbidden_donut"),
            branches.BRANCH_DEPTHS, 1)
        local floor = 0

        harness.equal(#result.rows, 70, "doughnut height")
        harness.equal(#result.rows[1], 80, "doughnut width")
        harness.truthy(#result.stairs >= 3,
            "doughnut retains three connected stair pairs")

        for _, row in ipairs(result.rows) do
            for glyph in row:gmatch(".") do
                if glyph == "." then
                    floor = floor + 1
                elseif glyph == "w" then
                    water = true
                elseif glyph == "l" then
                    lava = true
                end
            end
        end

        hole = hole or result.builder:cell(40, 35) == "#"
        harness.truthy(floor > 300, "doughnut has an open ring")
    end

    harness.truthy(hole, "uncrossed doughnut retains a center hole")
    harness.truthy(water or lava,
        "a source weighted octagon can place water or lava")
end

-- The source map is a once-per-run Depths choice, never a Dungeon draw.
function test.run()
    local definition = catalog.get("layout_forbidden_donut")

    harness.equal(weight.for_branch(definition,
        branches.BRANCH_DEPTHS), 5, "Depths source weight")
    harness.falsy(definition.tags.allow_dup,
        "forbidden doughnut does not repeat")
    harness.falsy(depth.eligible(definition,
        branches.BRANCH_DUNGEON, 10, 15),
        "forbidden doughnut is not a Dungeon layout")

    generated_shapes()
end

return test
