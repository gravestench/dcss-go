local harness = require("tests.harness")
local component = require("constants.component")
local streams = require("constants.rng_streams")

local test = {}

function test.run()
    local chaos = require("policy.clouds.effects.chaos")
    local durations = {
        haste_aut = 0,
        might_aut = 0,
    }
    local ctx = {}

    function ctx:player()
        return 1
    end

    function ctx:random(stream)
        harness.equal(stream, streams.CLOUDS,
            "chaos selection uses the saved cloud stream")
        return 0
    end

    function ctx:get(_, kind)
        if kind == component.DURATIONS then
            return durations
        end
    end

    function ctx:set(_, kind, state)
        harness.equal(kind, component.DURATIONS)
        durations = state
    end

    chaos.apply(ctx, 1)

    harness.truthy(durations.haste_aut > 0,
        "chaos cloud applies a weighted player status")
end

return test
