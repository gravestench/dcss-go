-- Snakes to sticks replaces a hostile snake with a normal floor item and
-- removes the original actor from the shared spatial index.
local component = require("constants.component")
local events = require("policy.religion.xom.events")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local ids = require("ids.xom_events")
local items = require("ids.items")
local monsters = require("ids.monsters")
local streams = require("constants.rng_streams")

local test = {}

-- A zero class draw chooses javelins, and one source snake yields one
-- unbranded javelin on its old cell without a monster corpse or XP reward.
function test.run(ctx)
    local player = ctx:create()
    local owner = fixture.context(ctx, player)
    local snake = fixture.actor(ctx, monsters.MONS_ADDER, 9, 7, 12)

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

    harness.equal(events.apply(owner, player, ids.GOOD_SNAKES, 20, {
        stream = streams.RELIGION,
    }), 1)
    harness.falsy(ctx:has(snake, component.ACTOR))

    local found = false

    for _, item in ipairs(ctx:query({ component.ITEM, component.POSITION })) do
        local position = ctx:get(item, component.POSITION)
        local state = ctx:get(item, component.ITEM)

        if position.x == 9 and position.y == 7 and
            state.kind_id == items.MI_JAVELIN then
            harness.equal(state.quantity, 1)
            found = true
        end
    end

    harness.truthy(found)
end

return test
