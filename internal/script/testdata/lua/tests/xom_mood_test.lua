-- Xom's favour thresholds and bored clock belong to saved worship state.
-- These checks pin source drift before the action selector can use it.
local component = require("constants.component")
local gods = require("constants.gods")
local harness = require("tests.harness")
local mood = require("policy.religion.xom.mood")
local piety = require("policy.religion.piety")
local streams = require("constants.rng_streams")

local test = {}

-- The source has a 150-point boundary between favourite and beloved.
-- Without it, two distinct Xom descriptions collapse into one rank.
local function source_ranks()
    harness.equal(piety.rank(gods.XOM, 150), 5)
    harness.equal(piety.rank(gods.XOM, 151), 6)
    harness.equal(piety.rank(gods.XOM, 181), 7)
end

-- A zero on the 1-in-20 check drifts outward one point at the midpoint.
-- The final coinflip lets Xom lose one interest point in the same tick.
local function one_tick(ctx)
    local player = ctx:create()

    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.XOM,
        piety = 100,
        gift_timeout = 10,
    })

    local expected = {
        {
            bound = 20,
            value = 0,
        },

        {
            bound = 2,
            value = 0,
        },

        {
            bound = 1000,
            value = 0,
        },

        {
            bound = 2,
            value = 0,
        },
    }
    local index = 0
    local wrapper = setmetatable({}, { __index = ctx })

    function wrapper:random(stream, bound)
        index = index + 1

        harness.equal(stream, streams.RELIGION)
        harness.equal(bound, expected[index].bound)

        return expected[index].value
    end

    mood.drift(wrapper, player, streams.RELIGION)

    local worship = ctx:get(player, component.RELIGION_WORSHIP)

    harness.equal(worship.piety, 101)
    harness.equal(worship.gift_timeout, 9)
    harness.equal(index, #expected)
end

-- Both checks use the production piety and mood owners.
function test.run(ctx)
    source_ranks()
    one_tick(ctx)
end

return test
