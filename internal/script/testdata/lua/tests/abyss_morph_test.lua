-- The morph clock resamples due cells without changing branch depth or
-- decaying authored travel terrain. Fixtures use production IDs and the
-- same sampler the live moving-window system invokes.
local abyss = require("constants.abyss")
local harness = require("tests.harness")
local morph = require("policy.world.abyss.morph")
local terrain = require("constants.terrain")

local test = {}

-- The first sample is due; the second is a permanent exit. A long
-- player action makes the integer source clock cross both deadlines.
function test.run()
    local ctx = {}
    local player = {}
    local cells = {
        ["2:2"] = terrain.DNGN_FLOOR,
        ["3:3"] = terrain.DNGN_EXIT_ABYSS,
    }

    function ctx:cell(level_id, x, y)
        harness.equal(level_id, abyss.LEVEL_ID)

        return cells[x .. ":" .. y]
    end

    function ctx:records_at()
        return {}
    end

    function ctx:actor_at(_, x, y)
        if x == 2 and y == 2 then
            return player
        end

        return nil
    end

    function ctx:worley()
        return {
            distance = { 0.25, 0.75 },
            id = { 0, 1 },
        }
    end

    function ctx:hash3_quotient_mod()
        return 500
    end

    function ctx:set_cell(_, x, y, feature)
        cells[x .. ":" .. y] = feature
    end

    local state = {
        branch_depth = 3,
        morph_depth = 100,
        phase = 0,
        world_x = 1,
        world_y = 1,
        sample_queue = {
            { x = 2, y = 2, change = 101, feature = terrain.DNGN_FLOOR },
            { x = 3, y = 3, change = 102, feature = terrain.DNGN_FLOOR },
        },
        borrowed_layout = { { terrain.DNGN_FLOOR } },
    }
    local updated = morph.advance(ctx, state, player, 1000)

    harness.equal(updated.branch_depth, 3)
    harness.equal(updated.morph_depth, 180)
    harness.truthy(updated.phase > 0)
    harness.equal(#updated.sample_queue, 1)
    harness.equal(updated.sample_queue[1].x, 2)
    harness.truthy(updated.sample_queue[1].change > 180)
    harness.equal(cells["3:3"], terrain.DNGN_EXIT_ABYSS)
end

return test
