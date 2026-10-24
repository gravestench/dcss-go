-- Xom's harmful draining lowers temporary maximum HP and stores the
-- ordinary recovery status; permanent base HP must remain untouched.
local component = require("constants.component")
local events = require("policy.religion.xom.events")
local event_ids = require("ids.xom_events")
local harness = require("tests.harness")
local streams = require("constants.rng_streams")

local test = {}

-- The exact round-off may vary with the religion stream, but source power
-- 100 always applies at least one point of recoverable drain here.
function test.run(ctx)
    local player = ctx:create()

    ctx:add(player, component.HEALTH, {
        current = 40,
        max = 40,
    })

    events.apply(ctx, player, event_ids.BAD_DRAINING, 20, {
        stream = streams.RELIGION,
    })

    local health = ctx:get(player, component.HEALTH)
    local drain = ctx:get(player, "status.drain")

    harness.truthy(drain)
    harness.truthy(health.max < 40)
    harness.equal(health.max + drain.amount, 40)
end

return test
