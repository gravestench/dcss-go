-- Xom moves real actors through the common grid owner. These tests use
-- the production position schema and a sparse grid fixture for sight.
local component = require("constants.component")
local events = require("policy.religion.xom.events")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local ids = require("ids.xom_events")
local monsters = require("ids.monsters")
local streams = require("constants.rng_streams")

local test = {}

-- A swap must move both actors as one batch. Moving the player first with
-- the single-actor API would fail because the monster still occupies it.
local function swap_with_player(ctx)
    local player = ctx:create()
    local owner = fixture.context(ctx, player)
    local monster = fixture.actor(ctx, monsters.MONS_ORC, 9, 7, 20)

    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 7,
        y = 7,
    })

    function owner:random(stream, bound)
        if stream == streams.RELIGION then
            return bound == 2 and 1 or 0
        end

        return ctx:random(stream, bound)
    end

    local changed = events.apply(owner, player,
        ids.BAD_SWAP_MONSTERS, 10, {
            stream = streams.RELIGION,
        })

    harness.truthy(changed)
    harness.equal(ctx:get(player, component.POSITION).x, 9)
    harness.equal(ctx:get(monster, component.POSITION).x, 7)

    ctx:destroy(monster)
    ctx:destroy(player)
end

-- The blink action considers hostile, mobile monsters in no-trans sight.
-- Its destination may vary, but the actor must leave its original cell.
local function blink_hostile(ctx)
    local player = ctx:create()
    local owner = fixture.context(ctx, player)
    local monster = fixture.actor(ctx, monsters.MONS_ORC, 9, 7, 20)

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

    local changed = events.apply(owner, player,
        ids.BAD_BLINK_MONSTERS, 10, {
            stream = streams.RELIGION,
        })

    harness.equal(changed, 1)
    harness.truthy(ctx:get(monster, component.POSITION).x ~= 9 or
        ctx:get(monster, component.POSITION).y ~= 7)
end

-- Separate cases avoid one actor's new position influencing the next.
function test.run(ctx)
    swap_with_player(ctx)
    blink_hostile(ctx)
end

return test
