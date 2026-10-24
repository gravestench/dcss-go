-- Xom's trail is a saved player status that leaves ordinary cloud entities
-- on vacated cells, then expires through player aut rather than map visits.
local clouds = require("ids.clouds")
local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local streams = require("constants.rng_streams")
local trail = require("policy.religion.xom.cloud_trail")

local test = {}

-- The duration and kind are chosen once. A later move rolls only the cloud
-- lifetime, so a save can resume with the same chosen cloud kind.
local function start_leave_expire(ctx)
    local player = ctx:create()
    local owner = fixture.context(ctx, player)
    local draws = {
        {
            bound = 601,
            value = 0,
        },

        {
            bound = 50,
            value = 0,
        },

        {
            bound = 8,
            value = 0,
        },
    }
    local used = 0

    function owner:random(stream, bound)
        used = used + 1

        harness.equal(stream, streams.RELIGION)
        harness.equal(bound, draws[used].bound)

        return draws[used].value
    end

    trail.start(owner, player, streams.RELIGION)

    local status = ctx:get(player, component.XOM_CLOUD_TRAIL)

    harness.equal(status.remaining_aut, 600)
    harness.equal(status.cloud_kind, clouds.CLOUD_CHAOS)

    local placed = trail.leave(owner, player, {
        level_id = 1,
        x = 7,
        y = 7,
    }, streams.RELIGION)

    harness.truthy(placed)

    local entity = ctx:query({ component.WORLD_CLOUD })[1]
    local cloud = ctx:get(entity, component.WORLD_CLOUD)

    harness.equal(cloud.kind_id, clouds.CLOUD_CHAOS)
    harness.equal(cloud.decay_aut, 30)

    trail.tick(owner, player, 600)

    harness.truthy(not ctx:has(player, component.XOM_CLOUD_TRAIL))
    harness.equal(used, #draws)
end

-- Use the same cloud placement owner that walking will call in live play.
function test.run(ctx)
    start_leave_expire(ctx)
end

return test
