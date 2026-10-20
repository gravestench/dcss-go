-- The final source pool layouts share geometry but have distinct branch
-- eligibility, canyon shapes, and postpasses. Use the production catalog
-- to verify that all four become executable definitions.
local branches = require("ids.branches")
local catalog = require("policy.generation.layouts.catalog")
local depth = require("policy.generation.vaults.depth")
local harness = require("tests.harness")
local weight = require("policy.generation.vaults.weight")

local test = {}

local gehenna = {
    "layout_gehenna_pools_basic",
    "layout_gehenna_pools_box",
    "layout_gehenna_pools_triple",
}

-- Give each level its own reproducible layout stream without introducing
-- test-only geometry or a second interpretation of the source DES fields.
local function context_for(seed)
    local state = seed
    local context = {}

    -- Match the kernel's high/low uint64 draw contract for bounded rolls.
    function context:random_u64(stream)
        harness.equal(stream, "layout", "pool layout random stream")
        state = (state * 1664525 + 1013904223) % 4294967296

        return state, (state * 22695477 + 1) % 4294967296
    end

    return context
end

-- Source maps must produce a full playable grid after their own cleanup
-- and the common connected-stair pass.
local function generate(id, branch_id, local_depth)
    local definition = catalog.get(id)
    local result = catalog.execute(context_for(local_depth * 79 + #id),
        definition, branch_id, local_depth)
    local floor = 0

    harness.equal(result.id, id, "executed pool layout ID")
    harness.equal(#result.rows, 70, "pool layout height")
    harness.equal(#result.rows[1], 80, "pool layout width")
    harness.truthy(#result.stairs >= 3,
        "pool layout has connected ordinary stairs")

    for _, row in ipairs(result.rows) do
        for glyph in row:gmatch(".") do
            if glyph == "." then
                floor = floor + 1
            end
        end
    end

    harness.truthy(floor > 840,
        id .. " preserves the source open-area requirement: " .. floor)

    return result
end

-- All three Gehenna variants share a fifteen-percent open-area validator
-- and weight ten, but the shape hook must remain distinct for each name.
local function gehenna_family()
    local total_rooms = 0
    local total_lava = 0
    local total_authored_up = 0

    for _, id in ipairs(gehenna) do
        local definition = catalog.get(id)

        harness.equal(weight.for_branch(definition,
            branches.BRANCH_GEHENNA), 10, id .. " Gehenna weight")
        harness.falsy(depth.eligible(definition,
            branches.BRANCH_DUNGEON, 1, 15),
            id .. " is not a Dungeon layout")

        for local_depth = 1, 5 do
            local result = generate(id,
                branches.BRANCH_GEHENNA, local_depth)

            harness.truthy(result.pool_count > 0,
                id .. " grows source pools")
            total_rooms = total_rooms + result.room_count
            total_authored_up = total_authored_up +
                result.authored_up_count

            for _, row in ipairs(result.rows) do
                for glyph in row:gmatch(".") do
                    if glyph == "l" then
                        total_lava = total_lava + 1
                    end
                end
            end
        end
    end

    harness.truthy(total_rooms > 0,
        "Gehenna family places source stone buildings")
    harness.truthy(total_lava > 0,
        "Gehenna family places source lava pools")
    harness.truthy(total_authored_up > 0,
        "Gehenna family sometimes authors its up stairs")
end

-- Honeycomb's source pool is shared by Snake, Depths, and Tartarus.
-- Snake's final level is excluded by its DES depth rule.
local function honeycomb_family()
    local definition = catalog.get("layout_honeycomb")

    harness.equal(weight.for_branch(definition,
        branches.BRANCH_SNAKE), 10, "Snake honeycomb weight")
    harness.equal(weight.for_branch(definition,
        branches.BRANCH_DEPTHS), 15, "Depths honeycomb weight")
    harness.equal(weight.for_branch(definition,
        branches.BRANCH_TARTARUS), 10, "Tartarus honeycomb weight")
    harness.falsy(depth.eligible(definition,
        branches.BRANCH_SNAKE, 4, 4),
        "honeycomb excludes Snake's final level")

    for local_depth = 1, 3 do
        local snake = generate("layout_honeycomb",
            branches.BRANCH_SNAKE, local_depth)
        local depths = generate("layout_honeycomb",
            branches.BRANCH_DEPTHS, local_depth)
        local tartarus = generate("layout_honeycomb",
            branches.BRANCH_TARTARUS, local_depth)

        harness.truthy(snake.pool_count > 0,
            "Snake honeycomb creates bordered territories")
        harness.truthy(depths.pool_count > 0,
            "Depths honeycomb creates bordered territories")
        harness.truthy(tartarus.pool_count > 0,
            "Tartarus honeycomb creates bordered territories")
    end
end

-- Together these hooks complete the active definitions in layout_pools.des.
function test.run()
    catalog.load()
    gehenna_family()
    honeycomb_family()
end

return test
