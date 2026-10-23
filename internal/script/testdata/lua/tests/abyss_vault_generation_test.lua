-- The Abyss sampler paints typed terrain. Authored DES maps then overlay
-- only their occupied cells, keeping the surrounding sampled floor.
local abyss = require("constants.abyss")
local branches = require("ids.branches")
local catalog = require("policy.generation.vaults.catalog")
local harness = require("tests.harness")
local terrain = require("constants.terrain")
local vaults = require("policy.generation.abyss.vaults")

local test = {}

-- The same named draw interface used by the production map builder
-- controls rotation and any source SUBST choices in this test.
local function context()
    local world = {}

    function world:random_u64()
        return 0, 17
    end

    return world
end

-- Painting one source map must produce typed records with the same ID,
-- while an untouched sample remains exactly as the sampler supplied it.
function test.run()
    local cells = {}

    for y = 1, abyss.HEIGHT do
        cells[y] = {}

        for x = 1, abyss.WIDTH do
            cells[y][x] = terrain.DNGN_FLOOR
        end
    end

    cells[2][2] = terrain.DNGN_DEEP_WATER

    local definition = catalog.get("abyss_furniture_001")
    local player = {
        branch_id = branches.BRANCH_ABYSS,
        depth = 3,
        branch_bottom = 7,
        absolute_depth = 25,
    }
    local result = vaults.place_one(context(), cells,
        definition, player)

    harness.equal(result.cells[2][2], terrain.DNGN_DEEP_WATER)
    harness.equal(result.id, definition.id)
    harness.truthy(#result.occupied > 0)

    -- The moving window must know every painted cell, including plain
    -- floor glyphs that have no gameplay effect or keyed DES directive.
    local recorded = {}

    for _, record in ipairs(result.records) do
        recorded[record.x .. ":" .. record.y] = true
    end

    for _, point in ipairs(result.occupied) do
        harness.truthy(recorded[point.x .. ":" .. point.y],
            "Abyss vault has an untracked occupied cell")
    end

    -- The exit map carries a MONS directive. Its deferred actor intent
    -- must remain after terrain has been projected for later population.
    local exit = vaults.place_one(context(), cells,
        catalog.get("evilmike_abyss_exit_16"), player)

    harness.truthy(#exit.records > 0)
end

return test
