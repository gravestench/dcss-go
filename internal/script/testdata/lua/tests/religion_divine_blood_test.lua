-- Kiku samples each LOS_SOLID cell independently before asking whether
-- that cell can hold blood. A forbidden terrain square still consumes its
-- own three-in-four draw and does not shift later outcomes.
local blood = require("policy.combat.divine_blood")
local component = require("constants.component")
local harness = require("tests.harness")
local streams = require("constants.rng_streams")
local terrain = require("constants.terrain")

local test = {}

-- Supply generic grid operations and fixed religion draws around one actor.
-- The production area tracer decides sight; this fixture only has open cells.
function test.run()
    local marked = { ["3,3"] = true }
    local draws = 0
    local ctx = {}

    function ctx:get(_, id)
        harness.equal(id, component.POSITION)

        return { level_id = 1, x = 3, y = 3 }
    end

    function ctx:walkable()
        return true
    end

    function ctx:actor_at()
        return nil
    end

    function ctx:cell(_, x, y)
        if x == 3 and y == 2 then
            return terrain.DNGN_FOUNTAIN_BLUE
        end

        return terrain.DNGN_FLOOR
    end

    function ctx:cell_blood(_, x, y)
        return marked[x .. "," .. y] or false
    end

    function ctx:set_cell_blood(_, x, y, value)
        marked[x .. "," .. y] = value
    end

    function ctx:random(stream, bound)
        harness.equal(stream, streams.RELIGION)
        harness.equal(bound, 4)
        draws = draws + 1

        return draws == 1 and 0 or 1
    end

    blood.spread(ctx, 1, 1)

    harness.equal(draws, 9)
    harness.falsy(marked["2,2"], "first failed draw stays dry")
    harness.falsy(marked["3,2"], "clean fountain rejects blood")
    harness.truthy(marked["4,2"], "later draw is independent")
    harness.truthy(marked["3,3"], "existing blood survives")
end

return test
