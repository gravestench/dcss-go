-- An interesting event changes Xom's saved interest immediately. The
-- ecumenical altar uses this same owner instead of parking an inert effect.
local component = require("constants.component")
local gods = require("constants.gods")
local harness = require("tests.harness")
local handler = require("policy.religion.gods.xom")
local stimulation = require("policy.religion.xom.stimulation")
local streams = require("constants.rng_streams")

local test = {}

-- Fix the only interestingness draw so the test also catches a Faith or
-- gift-timeout path that unexpectedly changes the source RNG bound.
local function interest(ctx)
    local player = ctx:create()

    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.XOM,
        piety = 100,
        gift_timeout = 5,
    })

    local wrapper = setmetatable({}, { __index = ctx })
    local draws = 0

    function wrapper:random(stream, bound)
        draws = draws + 1

        harness.equal(stream, streams.RELIGION)
        harness.equal(bound, 200)

        return 150
    end

    stimulation.apply(wrapper, player, 200)

    harness.equal(ctx:get(player, component.RELIGION_WORSHIP)
        .gift_timeout, 150)
    harness.equal(draws, 1)

    -- Source ecumenical Xom stimulation executes at conversion time.
    handler.ecumenical_bonus(wrapper, player)

    harness.equal(draws, 2)
    harness.equal(ctx:get(player, component.RELIGION_WORSHIP)
        .gift_timeout, 150)
end

-- Run through the live worship component and the god's normal entry hook.
function test.run(ctx)
    interest(ctx)
end

return test
