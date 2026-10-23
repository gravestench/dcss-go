-- Source layout families should be composable policy, with the exact
-- numeric kernel supplied by the ordinary context API.
local constants = require("constants.abyss")
local harness = require("tests.harness")
local sampler = require("policy.generation.abyss.sampler")
local terrain = require("constants.terrain")

local test = {}

-- This context pins a cellular point and hashes so the layout decisions,
-- rather than an accidental Go random stream, determine these features.
local function context()
    local world = {}

    function world:worley()
        return {
            distance = { 0.25, 0.75 },
            id = { 0, 1 },
        }
    end

    function world:hash3_quotient_mod()
        return 0
    end

    function world:fbm3()
        return 0
    end

    function world:xor_u32()
        return 0
    end

    return world
end

-- Positive source coordinates inside the Wastes use its sparse rock
-- texture and preserve a future change point for morphing.
function test.run(ctx)
    local state = {
        world_x = 1,
        world_y = 1,
        morph_depth = 100,
        borrowed_layout = {
            { terrain.DNGN_FLOOR },
        },
    }
    local feature, change = sampler.sample(context(), state, 0, 0)

    harness.equal(feature, terrain.DNGN_ROCK_WALL)
    harness.truthy(change > state.morph_depth)
    harness.equal(constants.WIDTH, 80)
    harness.equal(constants.HEIGHT, 70)

    -- A zero world coordinate selects the outer borrowed/river blend.
    -- Use the actual bridge here to exercise every nested layout's
    -- coordinate translation and source integer ranges.
    state.world_x = 0
    state.world_y = 0
    local outer_feature, outer_change =
        sampler.sample(ctx, state, 0, 0)
    local replay_feature, replay_change =
        sampler.sample(ctx, state, 0, 0)

    harness.truthy(outer_feature ~= nil)
    harness.truthy(outer_change > state.morph_depth)
    harness.equal(replay_feature, outer_feature)
    harness.equal(replay_change, outer_change)
end

return test
