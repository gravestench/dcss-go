-- Xom detects real floor-item entities and requests the saved item marker.
-- Carried items and repeated stacks on one cell cannot create extra marks.
local component = require("constants.component")
local events = require("policy.religion.xom.events")
local event_ids = require("ids.xom_events")
local harness = require("tests.harness")
local items = require("ids.items")
local streams = require("constants.rng_streams")

local test = {}

-- Give two floor stacks one coordinate so the map marker remains a single
-- spatial fact. The third stack is carried and has no floor position.
local function item(ctx, x, y, carrier)
    local entity = ctx:create()

    ctx:add(entity, component.ITEM, {
        kind_id = items.POT_CURING,
        quantity = 1,
        plus = 0,
        charges = 0,
        ego = "",
    })

    if carrier then
        ctx:add(entity, component.CARRIED_BY, {
            holder = carrier,
        })
    else
        ctx:add(entity, component.POSITION, {
            level_id = 1,
            x = x,
            y = y,
        })
    end

    return entity
end

-- The production effect must ask for one saved marker at the floor cell;
-- this fixture only records that grid command, not a duplicate schema.
function test.run(ctx)
    local player = ctx:create()
    local marked = {}
    local proxy = setmetatable({}, { __index = ctx })

    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 7,
        y = 7,
    })

    item(ctx, 9, 7)
    item(ctx, 9, 7)
    item(ctx, nil, nil, player)

    -- Xom's source radius adds a 0–6 roll to seven plus severity.
    function proxy:random(stream, bound)
        harness.equal(stream, streams.RELIGION)
        harness.equal(bound, 7)

        return 0
    end

    -- A cell outside sight needs a green detected-item marker on the map.
    function proxy:visible()
        return false
    end

    -- The real context method stages the marker for save/restore. Here the
    -- counter exposes duplicate requests from two stacks on one square.
    function proxy:detect_item(_, x, y)
        local key = x .. ":" .. y

        marked[key] = (marked[key] or 0) + 1

        return true
    end

    local count = events.apply(proxy, player,
        event_ids.GOOD_DETECT_ITEMS, 4, {
            stream = streams.RELIGION,
        })

    harness.equal(count, 1)
    harness.equal(marked["9:7"], 1)
end

return test
