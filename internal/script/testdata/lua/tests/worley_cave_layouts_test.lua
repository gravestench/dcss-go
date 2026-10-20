-- Three source cave maps use Worley fields for chambers, icy islands,
-- and water-divided paths. Load their real DES and execute their Lua hooks.
local branches = require("ids.branches")
local catalog = require("policy.generation.layouts.catalog")
local depth = require("policy.generation.vaults.depth")
local harness = require("tests.harness")
local weight = require("policy.generation.vaults.weight")

local test = {}

-- Match the builder's uint64 draw contract without duplicating a layout.
local function context_for(seed)
    local state = seed
    local context = {}

    function context:random_u64(stream)
        harness.equal(stream, "layout", "Worley cave layout stream")
        state = (state * 1664525 + 1013904223) % 4294967296

        return state, (state * 22695477 + 1) % 4294967296
    end

    return context
end

-- A completed map needs enough contiguous plain floor for all three
-- paired stairs. Water and rock counts distinguish the Cocytus variants.
local function check(id, branch_id, expected_weight, water_glyph)
    local definition = catalog.get(id)
    local floor = 0
    local water = 0

    harness.equal(weight.for_branch(definition, branch_id),
        expected_weight, id .. " source weight")
    harness.truthy(depth.eligible(definition, branch_id, 1, 7),
        id .. " source branch eligibility")
    harness.falsy(depth.eligible(definition,
        branches.BRANCH_DUNGEON, 10, 15),
        id .. " does not enter Dungeon")

    for seed = 1, 3 do
        local result = catalog.execute(context_for(seed * 139),
            definition, branch_id, seed)

        harness.equal(result.id, id, "executed source layout ID")
        harness.equal(#result.rows, 70, "layout height")
        harness.equal(#result.rows[1], 80, "layout width")
        harness.truthy(#result.stairs >= 3,
            "layout has connected ordinary stairs")

        for _, row in ipairs(result.rows) do
            for glyph in row:gmatch(".") do
                if glyph == "." then
                    floor = floor + 1
                elseif glyph == water_glyph then
                    water = water + 1
                end
            end
        end
    end

    harness.truthy(floor > 300,
        id .. " has broad traversable cave passages")

    if water_glyph then
        harness.truthy(water > 100,
            id .. " retains source water terrain")
    end
end

-- The same branch catalog drives tests and the live selector; no local
-- copies of depth clauses or material weights may decide eligibility.
function test.run()
    check("layout_chambers", branches.BRANCH_SNAKE, 15)
    check("layout_chambers", branches.BRANCH_SPIDER, 5)
    check("layout_chambers", branches.BRANCH_PANDEMONIUM, 10)
    check("layout_cocytus_water_paths", branches.BRANCH_COCYTUS, 10, "w")
    check("layout_ice_bergs", branches.BRANCH_COCYTUS, 10, "w")
end

return test
