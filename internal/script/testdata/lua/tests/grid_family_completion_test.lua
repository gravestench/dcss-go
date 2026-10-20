-- The final two source grid layouts complete layout_grids.des. Exercise
-- their branch rules and geometry through the live layout catalog.
local branches = require("ids.branches")
local catalog = require("policy.generation.layouts.catalog")
local depth = require("policy.generation.vaults.depth")
local harness = require("tests.harness")
local weight = require("policy.generation.vaults.weight")

local test = {}

-- Reproducible high/low draws use the production layout stream contract.
local function context_for(seed)
    local state = seed
    local context = {}

    -- The builder requests a high and low half for unbiased bounded rolls.
    function context:random_u64(stream)
        harness.equal(stream, "layout", "grid layout random stream")
        state = (state * 1664525 + 1013904223) % 4294967296

        return state, (state * 22695477 + 1) % 4294967296
    end

    return context
end

-- Require real geometry and connected stairs for each branch that can draw
-- a source layout; merely registering its metadata is insufficient.
local function check(id, branch_id, expected_weight)
    local definition = catalog.get(id)

    harness.equal(weight.for_branch(definition, branch_id),
        expected_weight, id .. " source branch weight")
    harness.truthy(depth.eligible(definition, branch_id, 1, 5),
        id .. " is eligible in its source branch")
    harness.falsy(depth.eligible(definition,
        branches.BRANCH_DUNGEON, 1, 15),
        id .. " is not a Dungeon candidate")

    for seed = 1, 5 do
        local result = catalog.execute(context_for(seed * 113),
            definition, branch_id, seed)
        local floor = 0

        harness.equal(result.id, id, "executed grid layout ID")
        harness.equal(#result.rows, 70, "grid layout height")
        harness.equal(#result.rows[1], 80, "grid layout width")
        harness.truthy(#result.stairs >= 3,
            "grid layout has reachable ordinary stairs")

        for _, row in ipairs(result.rows) do
            for glyph in row:gmatch(".") do
                if glyph == "." then
                    floor = floor + 1
                end
            end
        end

        harness.truthy(floor > 150,
            id .. " carves a playable source grid: " .. floor)
    end
end

-- Cover Lair's broad grid and both branch selections of the shapes grid.
function test.run()
    catalog.load()
    check("layout_big_grid", branches.BRANCH_LAIR, 2)
    check("layout_grid_shapes", branches.BRANCH_SNAKE, 5)
    check("layout_grid_shapes", branches.BRANCH_PANDEMONIUM, 10)
end

return test
