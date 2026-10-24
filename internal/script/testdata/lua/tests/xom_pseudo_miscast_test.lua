-- A pseudo-miscast spends a Xom action on an ominous message while keeping
-- HP, terrain, and inventory untouched. Terrain can supply a priority line.
local channels = require("constants.message_channels")
local component = require("constants.component")
local events = require("policy.religion.xom.events")
local event_ids = require("ids.xom_events")
local harness = require("tests.harness")
local streams = require("constants.rng_streams")
local terrain = require("constants.terrain")

local test = {}

-- The real ECS actor is read by the event; only visible grid and message
-- capture are supplied by this tiny deterministic test world.
local function world(ctx, features, draws, messages)
    local proxy = setmetatable({}, { __index = ctx })
    local next_draw = 0

    function proxy:visible_cells()
        local cells = {}

        for index = 1, #features do
            cells[index] = {
                x = index,
                y = 1,
            }
        end

        return cells
    end

    function proxy:cell(_, x)
        return features[x] or terrain.DNGN_FLOOR
    end

    function proxy:random(stream, bound)
        harness.equal(stream, streams.RELIGION)
        next_draw = next_draw + 1

        local draw = draws[next_draw]

        harness.truthy(draw ~= nil and draw < bound,
            "invalid pseudo-miscast draw")

        return draw
    end

    function proxy:emit(channel, message)
        harness.equal(channel, channels.RELIGION)
        messages[#messages + 1] = message
    end

    return proxy
end

-- The source always has a fallback, even on an empty floor.
local function fallback(ctx, player)
    local messages = {}
    local proxy = world(ctx, {}, { 0, 0 }, messages)

    events.apply(proxy, player, event_ids.BAD_MISCAST_PSEUDO, 4, {
        stream = streams.RELIGION,
    })

    harness.equal(messages[1], "Nothing appears to happen... Ominous!")
end

-- An idol is a priority visual. Coinflip plus index choose its specific
-- line without changing the level's feature or the player's health.
local function idol_priority(ctx, player)
    local messages = {}
    local proxy = world(ctx, {
        terrain.DNGN_ORCISH_IDOL,
    }, { 0, 0, 0 }, messages)

    events.apply(proxy, player, event_ids.BAD_MISCAST_PSEUDO, 4, {
        stream = streams.RELIGION,
    })

    harness.equal(messages[1],
        "The idol of Beogh turns to glare at you.")
end

-- Neither choice can change persistent state; it only emits one line.
function test.run(ctx)
    local player = ctx:create()

    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 7,
        y = 7,
    })
    ctx:add(player, component.HEALTH, {
        current = 20,
        max = 20,
    })

    fallback(ctx, player)
    idol_priority(ctx, player)

    harness.equal(ctx:get(player, component.HEALTH).current, 20)
end

return test
