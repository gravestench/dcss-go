-- Xom estimates whether a floor still has surprises before offering
-- mapping or a journey. The source distinguishes mapped from visited cells.
local exploration = require("policy.religion.xom.exploration")
local harness = require("tests.harness")
local streams = require("constants.rng_streams")
local terrain = require("constants.terrain")

local test = {}

-- Sample the two cells equally. A magic-mapped cell counts as known for
-- divination but remains unexplored for teleportation.
local function mapped_is_not_seen(ctx)
    local calls = 0
    local proxy = setmetatable({}, { __index = ctx })

    function proxy:level_size()
        return 2, 1
    end

    function proxy:random(stream, bound)
        harness.equal(stream, streams.RELIGION)
        harness.equal(bound, 2)
        calls = calls + 1

        return (calls - 1) % 2
    end

    function proxy:cell()
        return terrain.DNGN_FLOOR
    end

    function proxy:walkable()
        return true
    end

    function proxy:solid()
        return false
    end

    function proxy:remembered(_, x)
        return x == 0 and terrain.DNGN_FLOOR or nil
    end

    function proxy:seen()
        return false
    end

    harness.equal(exploration.estimate(proxy, 1, false,
        streams.RELIGION), 50)
    harness.equal(exploration.estimate(proxy, 1, true,
        streams.RELIGION), 0)
end

-- A solid wall surrounded only by other opaque walls cannot be explored.
-- The bounded sampler must still terminate with source's 100% fallback.
local function sealed_wall_is_not_sampled(ctx)
    local proxy = setmetatable({}, { __index = ctx })

    function proxy:level_size()
        return 1, 1
    end

    function proxy:random()
        return 0
    end

    function proxy:cell()
        return terrain.DNGN_ROCK_WALL
    end

    function proxy:walkable()
        return false
    end

    function proxy:solid()
        return true
    end

    function proxy:opaque()
        return true
    end

    function proxy:remembered()
        return nil
    end

    function proxy:seen()
        return false
    end

    harness.equal(exploration.estimate(proxy, 1, false,
        streams.RELIGION), 100)
end

-- Deep water is impassable to many actors, but it is open terrain in the
-- source exploration rule. Movement eligibility must not classify walls.
local function water_is_open_terrain(ctx)
    local proxy = setmetatable({}, { __index = ctx })

    function proxy:level_size()
        return 1, 1
    end

    function proxy:random()
        return 0
    end

    function proxy:cell(_, x, y)
        if x ~= 0 or y ~= 0 then
            return nil
        end

        return terrain.DNGN_DEEP_WATER
    end

    function proxy:walkable()
        return false
    end

    function proxy:solid()
        return false
    end

    function proxy:opaque()
        return false
    end

    function proxy:remembered()
        return nil
    end

    function proxy:seen()
        return false
    end

    harness.equal(exploration.estimate(proxy, 1, false,
        streams.RELIGION), 0)
end

-- Exercise the production estimator through a small deterministic grid.
function test.run(ctx)
    mapped_is_not_seen(ctx)
    sealed_wall_is_not_sampled(ctx)
    water_is_open_terrain(ctx)
end

return test
