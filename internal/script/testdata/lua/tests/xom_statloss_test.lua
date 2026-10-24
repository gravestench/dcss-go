-- Xom drains a saved attribute, but a non-nasty act cannot reduce the
-- selected current stat to zero. Recovery remains the ordinary XP path.
local component = require("constants.component")
local events = require("policy.religion.xom.events")
local event_ids = require("ids.xom_events")
local gods = require("constants.gods")
local harness = require("tests.harness")
local stats = require("constants.stats")
local streams = require("constants.rng_streams")

local test = {}

-- Pin Xom's stat draw while leaving the ordinary stat recovery timer on
-- its production stream and schema.
local function choose_strength(ctx)
    local proxy = setmetatable({}, { __index = ctx })

    function proxy:random(stream, bound)
        if stream == streams.RELIGION then
            harness.equal(bound, #stats.ORDER)

            return 0
        end

        return ctx:random(stream, bound)
    end

    return proxy
end

-- A one-point current stat is protected while Xom is interested.
local function safe_floor(ctx)
    local player = ctx:create()

    ctx:add(player, component.ATTRIBUTES, {
        strength = 1,
        intelligence = 10,
        dexterity = 10,
    })
    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.XOM,
        piety = 100,
        gift_timeout = 10,
    })

    events.apply(choose_strength(ctx), player,
        event_ids.BAD_STATLOSS, 20, {
            stream = streams.RELIGION,
        })

    harness.equal(ctx:get(player, component.STAT_LOSS), nil)
end

-- A normal stat loses one point and stores the source recovery status.
local function drains_saved_stat(ctx)
    local player = ctx:create()

    ctx:add(player, component.ATTRIBUTES, {
        strength = 10,
        intelligence = 10,
        dexterity = 10,
    })
    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.XOM,
        piety = 100,
        gift_timeout = 10,
    })

    events.apply(choose_strength(ctx), player,
        event_ids.BAD_STATLOSS, 20, {
            stream = streams.RELIGION,
        })

    harness.equal(ctx:get(player, component.STAT_LOSS).strength, 1)
end

-- Both branches use the production event catalog and stat drain owner.
function test.run(ctx)
    safe_floor(ctx)
    drains_saved_stat(ctx)
end

return test
