-- A live monster can occupy a saved reciprocal stair after the player
-- leaves. Returning must choose nearby free terrain without rewriting it.
local harness = require("tests.harness")
local landing = require("policy.world.stair_landing")

local test = {}

-- Keep the fake service to the three queries used by production landing
-- search; no duplicate ECS schema or terrain decoder belongs in this test.
local function context(occupied)
    local ctx = {}

    function ctx:level_size()
        return 5, 5
    end

    function ctx:walkable(_, x, y)
        return x > 0 and x < 4 and y > 0 and y < 4
    end

    function ctx:actor_at(_, x, y)
        return occupied[x .. ":" .. y]
    end

    return ctx
end

-- Search order is stable, so equal-distance options do not depend on a
-- Lua table traversal or a new random draw during stair travel.
function test.run()
    local free = context({})
    local x, y = landing.find(free, 1, 2, 2)

    harness.equal(x, 2, "unoccupied stair keeps its x")
    harness.equal(y, 2, "unoccupied stair keeps its y")

    local occupied = context({
        ["2:2"] = true,
        ["3:2"] = true,
    })

    x, y = landing.find(occupied, 1, 2, 2)

    harness.equal(x, 1, "occupied stair uses adjacent free cell")
    harness.equal(y, 2, "arrival stays beside the linked stair")
end

return test
