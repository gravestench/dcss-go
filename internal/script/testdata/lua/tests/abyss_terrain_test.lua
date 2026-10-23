-- The procedural window stores actual typed features and the next
-- morph point for every sampled cell. A save can therefore replay a
-- future shift without guessing which cells were due to change.
local abyss = require("constants.abyss")
local harness = require("tests.harness")
local policy = require("policy.generation.abyss.terrain")
local terrain = require("constants.terrain")

local test = {}

-- A deterministic Wastes cell is floor here; using a fake numeric
-- context keeps this test about the dense grid and queue contract.
local function context()
    local world = {}

    function world:worley()
        return {
            distance = { 0.25, 0.75 },
            id = { 0, 1 },
        }
    end

    function world:hash3_quotient_mod()
        return 500
    end

    return world
end

-- The window retains its immutable outer wall and one queue entry per
-- procedural interior cell, ordered by change depth.
function test.run()
    local state = {
        world_x = 1,
        world_y = 1,
        morph_depth = 100,
        sample_queue = {},
        borrowed_layout = {
            { terrain.DNGN_FLOOR },
        },
    }
    local cells, updated = policy.build(context(), state)

    harness.equal(#cells, abyss.HEIGHT)
    harness.equal(#cells[1], abyss.WIDTH)
    harness.equal(cells[1][1], terrain.DNGN_ROCK_WALL)
    harness.equal(cells[abyss.CENTRE_Y + 1][abyss.CENTRE_X + 1],
        terrain.DNGN_FLOOR)
    harness.equal(#updated.sample_queue,
        (abyss.WIDTH - 2) * (abyss.HEIGHT - 2))
    harness.truthy(updated.sample_queue[1].change > state.morph_depth)
    harness.equal(#state.sample_queue, 0)
end

return test
