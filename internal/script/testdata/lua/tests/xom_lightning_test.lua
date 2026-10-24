-- Xom's divine lightning is a radius-two electric explosion centered on
-- the player. The source blast has a hole in the middle, sparing its host.
local component = require("constants.component")
local events = require("policy.religion.xom.events")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local ids = require("ids.xom_events")
local monsters = require("ids.monsters")
local streams = require("constants.rng_streams")

local test = {}

-- The two-step target is in the explosion while a three-step target is
-- outside it. A high roll should wound only the former and never the host.
function test.run(ctx)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN,
        7, 7, 100)
    local owner = fixture.context(ctx, player)
    local near = fixture.actor(ctx, monsters.MONS_ORC,
        9, 7, 1)
    local far = fixture.actor(ctx, monsters.MONS_ORC,
        10, 7, 100)

    -- Xom's Religion stream pays the source's three thirty-sided dice.
    function owner:random(stream, bound)
        if stream == streams.RELIGION then
            return bound - 1
        end

        return ctx:random(stream, bound)
    end

    -- Source KILL_MISC never awards the player a kill for this blast.
    function owner:signal(kind)
        harness.falsy(kind == "player_kill")
    end

    events.apply(owner, player, ids.GOOD_LIGHTNING, 20, {
        stream = streams.RELIGION,
    })

    harness.equal(ctx:get(player, component.HEALTH).current, 100)
    harness.equal(ctx:get(near, component.HEALTH).current, 0)
    harness.equal(ctx:get(far, component.HEALTH).current, 100)
end

return test
