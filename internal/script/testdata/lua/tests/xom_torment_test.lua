-- Xom torments the player alone, using the existing resistance rule.
-- The source action leaves at least one HP and does not torment monsters.
local component = require("constants.component")
local events = require("policy.religion.xom.events")
local event_ids = require("ids.xom_events")
local harness = require("tests.harness")
local streams = require("constants.rng_streams")

local test = {}

-- A plain forty-HP character takes the source half-current-HP-minus-one
-- loss, while an unrelated creature in the same world remains untouched.
function test.run(ctx)
    local player = ctx:create()
    local monster = ctx:create()

    ctx:add(player, component.PLAYER, {})
    ctx:add(player, component.HEALTH, {
        current = 40,
        max = 40,
    })
    ctx:add(monster, component.HEALTH, {
        current = 30,
        max = 30,
    })

    events.apply(ctx, player, event_ids.BAD_TORMENT, 20, {
        stream = streams.RELIGION,
    })

    harness.equal(ctx:get(player, component.HEALTH).current, 21)
    harness.equal(ctx:get(monster, component.HEALTH).current, 30)
end

return test
