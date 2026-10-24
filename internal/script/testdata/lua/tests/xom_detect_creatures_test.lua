-- Creature divination writes remembered monster markers, not live actor
-- positions. An unseen orc is sensed without exposing its entity handle.
local component = require("constants.component")
local events = require("policy.religion.xom.events")
local event_ids = require("ids.xom_events")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local streams = require("constants.rng_streams")

local test = {}

-- Use production actor components and player perception, while recording
-- only the grid marker commands that need a host-side save test later.
function test.run(ctx)
    local player = ctx:create()
    local orc = ctx:create()
    local markers = {}
    local cleared = 0
    local proxy = setmetatable({}, { __index = ctx })

    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 7,
        y = 7,
    })
    ctx:add(orc, component.ACTOR, {
        kind_id = monsters.MONS_ORC,
        speed = 10,
    })
    ctx:add(orc, component.POSITION, {
        level_id = 1,
        x = 9,
        y = 7,
    })
    ctx:add(orc, component.HEALTH, {
        current = 5,
        max = 5,
    })

    -- The player sees no cell through this fixture wall, so the monster
    -- must enter the source detector rather than normal visible entities.
    function proxy:player()
        return player
    end

    function proxy:visible()
        return false
    end

    -- Radius 9+0+4 includes the orc. A high fuzz roll suppresses the
    -- optional displacement and keeps this case about marker ownership.
    function proxy:random(stream, bound)
        harness.equal(stream, streams.RELIGION)

        if bound == 7 then
            return 0
        end

        harness.equal(bound, 100)

        return 99
    end

    -- Source detect_creatures clears old sensed glyphs before placing the
    -- new sample, so stale monsters do not remain on the map forever.
    function proxy:clear_detected_creatures()
        cleared = cleared + 1
    end

    -- This command stores a monster type at a perceived map coordinate,
    -- without giving the view access to the real actor identity.
    function proxy:detect_creature(_, x, y, kind_id)
        markers[#markers + 1] = {
            x = x,
            y = y,
            kind_id = kind_id,
        }

        return true
    end

    local count = events.apply(proxy, player,
        event_ids.GOOD_DETECT_CREATURES, 4, {
            stream = streams.RELIGION,
        })

    harness.equal(count, 1)
    harness.equal(cleared, 1)
    harness.equal(#markers, 1)
    harness.equal(markers[1].x, 9)
    harness.equal(markers[1].y, 7)
    harness.equal(markers[1].kind_id, monsters.MONS_ORC)
end

return test
