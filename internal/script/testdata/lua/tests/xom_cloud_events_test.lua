-- Fog and chaos use real cloud entities. Xom's messages must not be the
-- only observable effect of either action.
local clouds = require("ids.clouds")
local component = require("constants.component")
local events = require("policy.religion.xom.events")
local event_ids = require("ids.xom_events")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local streams = require("constants.rng_streams")

local test = {}

-- Zero rolls choose the first smoke colour and the minimum source counts.
-- The ordinary cloud owner decides occupancy and stores durations.
local function live_clouds(ctx)
    local player = ctx:create()
    local owner = fixture.context(ctx, player)

    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 7,
        y = 7,
    })

    function owner:random(stream, bound)
        if stream == streams.RELIGION then
            return 0
        end

        return ctx:random(stream, bound)
    end

    local placed = events.apply(owner, player,
        event_ids.GOOD_FOG, 50, {
            stream = streams.RELIGION,
        })

    harness.equal(placed, 8)
    harness.equal(#ctx:query({ component.WORLD_CLOUD }), 8)

    ctx:set(player, component.POSITION, {
        level_id = 1,
        x = 30,
        y = 30,
    })

    local entity = events.apply(owner, player,
        event_ids.BAD_CHAOS_CLOUD, 50, {
            stream = streams.RELIGION,
        })
    local cloud = ctx:get(entity, component.WORLD_CLOUD)

    harness.equal(cloud.kind_id, clouds.CLOUD_CHAOS)
    harness.equal(cloud.decay_aut, 30)
    harness.equal(cloud.spread_rate, 5)
    harness.equal(#ctx:query({ component.WORLD_CLOUD }), 9)
end

-- Run through effective Xom definitions and the shared placement policy.
function test.run(ctx)
    live_clouds(ctx)
end

return test
