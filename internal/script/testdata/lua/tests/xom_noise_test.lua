-- Xom's noise crosses Silence and reaches live monster hearing state.
-- A message alone cannot wake or redirect a hostile creature.
local component = require("constants.component")
local events = require("policy.religion.xom.events")
local event_ids = require("ids.xom_events")
local harness = require("tests.harness")
local streams = require("constants.rng_streams")
local terrain = require("constants.terrain")

local test = {}

-- Use a narrow corridor to make sound propagation deterministic while
-- keeping the real ECS AI state and production noise owner in the call.
local function corridor(ctx, player)
    local world = setmetatable({}, { __index = ctx })

    function world:player()
        return player
    end

    function world:cell(_, x, y)
        if y ~= 1 or x < 1 or x > 12 then
            return nil
        end

        return terrain.DNGN_FLOOR
    end

    function world:visible()
        return false
    end

    function world:aut()
        return 0
    end

    function world:random(stream, bound)
        harness.equal(stream, streams.RELIGION)
        harness.equal(bound, 19)

        return 0
    end

    return world
end

-- The player is silenced, so ordinary noise would stop at its origin.
-- Xom's fake noise should still give a nearby monster an investigation target.
function test.run(ctx)
    local player = ctx:create()
    local monster = ctx:create()

    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 1,
        y = 1,
    })
    ctx:add(player, component.PLAYER_STATUS, {
        silence_aut = 100,
    })
    ctx:add(monster, component.AI, {
        behavior = "wander",
    })
    ctx:add(monster, component.POSITION, {
        level_id = 1,
        x = 3,
        y = 1,
    })
    ctx:add(monster, component.HEALTH, {
        current = 5,
        max = 5,
    })

    events.apply(corridor(ctx, player), player,
        event_ids.BAD_NOISE, 20, {
            stream = streams.RELIGION,
        })

    harness.equal(ctx:get(monster, component.AI).target_x, 1)
end

return test
