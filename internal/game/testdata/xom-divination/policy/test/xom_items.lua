-- Exercise the production Xom effect through a named policy so the game
-- test can inspect the real grid marker after the structural commit.
local events = require("policy.religion.xom.events")
local ids = require("ids.xom_events")
local streams = require("constants.rng_streams")

local probe = {}

-- Invoke the same event dispatch used by worship and wrath. Returning the
-- count only reports the result; the map write stays staged by the grid.
function probe.run(ctx)
    local count = events.apply(ctx, ctx:player(),
        ids.GOOD_DETECT_ITEMS, 4, {
            stream = streams.RELIGION,
        })

    return {
        detected = count,
    }
end

-- Creature detection shares the production event dispatcher but stores a
-- sensed type on the map instead of revealing the actual actor identity.
function probe.creatures(ctx)
    local count = events.apply(ctx, ctx:player(),
        ids.GOOD_DETECT_CREATURES, 100, {
            stream = streams.RELIGION,
        })

    return {
        detected = count,
    }
end

register.policy({
    id = "test.xom_detect_items",
    run = probe.run,
})

register.policy({
    id = "test.xom_detect_creatures",
    run = probe.creatures,
})

return probe
