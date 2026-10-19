-- Chaos selection uses the saved cloud stream.

local harness = require("tests.harness")
local component = require("constants.component")
local streams = require("constants.rng_streams")

local test = {}

-- A zero cloud-stream draw chooses an effect and writes its player duration.
function test.run()
    local chaos = require("policy.clouds.effects.chaos")
    local durations = {
        haste_aut = 0,
        might_aut = 0,
    }
    local ctx = {}

    -- Chaos targets the player entity in this minimal fixture.
    function ctx:player()
        return 1
    end

    -- Pin selection without depending on the weighted pool's current order.
    function ctx:random(stream)
        harness.equal(stream, streams.CLOUDS,
            "chaos selection uses the saved cloud stream")
        return 0
    end

    -- Expose the shared duration component used by the selected status.
    function ctx:get(_, kind)
        if kind == component.DURATIONS then
            return durations
        end
    end

    -- Capture the mutation so the test checks an applied effect, not a return value.
    function ctx:set(_, kind, state)
        harness.equal(kind, component.DURATIONS)
        durations = state
    end

    chaos.apply(ctx, 1)

    harness.truthy(durations.haste_aut > 0,
        "chaos cloud applies a weighted player status")
end

return test
