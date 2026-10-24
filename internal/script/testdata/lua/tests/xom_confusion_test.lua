-- Xom's confusion uses the shared saved status rather than a private
-- message or counter; it must be visible to the ordinary movement rule.
local component = require("constants.component")
local events = require("policy.religion.xom.events")
local ids = require("ids.xom_events")
local harness = require("tests.harness")
local confusion = require("policy.magic.player_confusion")
local streams = require("constants.rng_streams")
local fixture = require("tests.monster_ally_support_fixture")
local monsters = require("ids.monsters")

local test = {}

-- The source selects five to seven turns, then may attempt to confuse
-- nearby monsters. No nearby actor is needed to verify the player timer.
function test.run(ctx)
    local player = ctx:create()
    local proxy = setmetatable({}, { __index = ctx })

    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 7,
        y = 7,
    })

    -- Fix Xom's draws while letting unrelated shared owners use their
    -- regular streams; this test must exercise the production status.
    function proxy:random(stream, bound)
        if stream == streams.RELIGION then
            return bound == 3 and 0 or bound - 1
        end

        return ctx:random(stream, bound)
    end

    events.apply(proxy, player, ids.BAD_CONFUSION, 40, {
        stream = streams.RELIGION,
    })

    harness.truthy(confusion.active(ctx, player))
    harness.equal(ctx:get(player,
        "zap.player_confusion").remaining_aut, 50)

    -- Good confusion must affect the live hostile's normal status, so
    -- its next monster turn reads the same timer as spell confusion.
    local monster = fixture.actor(ctx, monsters.MONS_ORC, 9, 7, 20)
    local owner = fixture.context(ctx, player)

    function owner:random(stream, bound)
        if stream == streams.RELIGION then
            return bound == 20 and 1 or 3
        end

        return ctx:random(stream, bound)
    end

    events.apply(owner, player, ids.GOOD_CONFUSION, 40, {
        stream = streams.RELIGION,
    })

    harness.truthy(ctx:get(monster, component.MONSTER_CONFUSION))
end

return test
