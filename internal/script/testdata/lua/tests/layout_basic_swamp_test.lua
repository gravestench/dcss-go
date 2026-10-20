-- The source Swamp builder paints its height field into mangrove, floor,
-- and shallow water. Exercise the production layout catalog and decoder.
local branches = require("ids.branches")
local catalog = require("policy.generation.layouts.catalog")
local features = require("content.terrain_features")
local harness = require("tests.harness")
local weight = require("policy.generation.vaults.weight")

local test = {}

-- A fixed stream makes the terrain contract repeatable without copying
-- the production heightmap implementation into the test fixture.
local function context_for(seed)
    local state = seed
    local context = {}

    function context:random_u64(stream)
        harness.equal(stream, "layout", "Swamp layout stream")
        state = (state * 48271) % 2147483647
        local high = state

        state = (state * 48271) % 2147483647

        return high, state
    end

    return context
end

-- Source margins remain mangrove while the slushy interior contains
-- both floor and shallow water at several Swamp depths.
local function check_depth(depth, seed)
    local definition = catalog.get("layout_basic_swamp")
    local result = catalog.execute(context_for(seed), definition,
        branches.BRANCH_SWAMP, depth)
    local cells = features.decode_source_rows(result.rows)
    local counts = {}

    harness.equal(weight.for_branch(definition, branches.BRANCH_SWAMP),
        20, "source Swamp layout weight")
    harness.truthy(#result.stairs >= 3, "Swamp layout stairs")

    for _, row in ipairs(cells) do
        for _, cell in ipairs(row) do
            counts[cell] = (counts[cell] or 0) + 1
        end
    end

    harness.equal(cells[1][1], "DNGN_MANGROVE", "Swamp margin")
    harness.truthy((counts.DNGN_MANGROVE or 0) > 1000,
        "Swamp has mangrove terrain")
    harness.truthy((counts.DNGN_FLOOR or 0) > 100,
        "Swamp has walkable islands")
    harness.truthy((counts.DNGN_SHALLOW_WATER or 0) > 100,
        "Swamp has slushy water")
end

-- The terrain mix responds to local branch depth while the source
-- declaration remains eligible throughout Swamp.
function test.run()
    check_depth(1, 2201)
    check_depth(4, 2202)
end

return test
