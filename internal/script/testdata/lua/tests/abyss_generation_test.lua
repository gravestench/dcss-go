-- Initial Abyss generation returns a typed level and a separate saved
-- procedural state. The center is made safe after terrain is sampled,
-- matching the source proto arrival rule.
local generator = require("policy.generation.abyss")
local harness = require("tests.harness")
local terrain = require("constants.terrain")
local component = require("constants.component")
local abyss_constants = require("constants.abyss")

local test = {}

-- Force a Wastes floor while retaining source-sized output. Vault and
-- proto overlays have their own tests and may alter these cells later.
local function context()
    local world = {}
    local player = {}

    -- The exit policy asks the saved player rune set whether it should
    -- use the faster post-rune escape odds.
    function world:player()
        return player
    end

    function world:get(entity, name)
        harness.equal(entity, player)
        harness.equal(name, component.PLAYER_RUNES)

        return { collected = {} }
    end

    function world:worley()
        return {
            distance = { 0.25, 0.75 },
            id = { 0, 1 },
        }
    end

    function world:hash3_quotient_mod()
        return 500
    end

    -- Authored furniture selection uses the same builder stream as live
    -- generation after the procedural sample has been drawn.
    function world:random_u64()
        return 0, 17
    end

    function world:random(_, bound)
        return bound - 1
    end

    return world
end

-- The caller owns commit, so generating this plan must not change the
-- state table supplied by the current session.
function test.run()
    local state = {
        branch_depth = 1,
        world_x = 1,
        world_y = 1,
        morph_depth = 100,
        sample_queue = {},
        borrowed_layout = {
            { terrain.DNGN_FLOOR },
        },
    }
    local level, updated = generator.generate(context(), state)

    harness.equal(level.id, abyss_constants.LEVEL_ID)
    harness.equal(level.local_depth, state.branch_depth)
    harness.equal(level.cells[36][41], terrain.DNGN_FLOOR)
    harness.truthy(#updated.sample_queue > 5000)
    harness.equal(#state.sample_queue, 0)
end

return test
