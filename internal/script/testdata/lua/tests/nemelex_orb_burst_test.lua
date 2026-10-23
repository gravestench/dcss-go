-- Source burst geometry launches three to seven evenly spaced persistent
-- orbs. This test observes launch calls while retaining real target scans.
local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local iood = require("policy.magic.effects.zaps.iood")
local orb = require("policy.religion.cards.effects.orb")
local monsters = require("ids.monsters")
local streams = require("constants.rng_streams")

local test = {}

-- With angle zero, the three-orb fan starts north and circles clockwise.
-- The aimed east rat becomes the preferred homing foe for its cone.
function test.run(ctx)
    local player = ctx:create()
    local owner = fixture.context(ctx, player)
    local rat = fixture.actor(ctx, monsters.MONS_RAT, 8, 7)
    local drawn = 0
    local launched = {}

    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 7,
        y = 7,
    })

    function owner:random(stream, bound)
        harness.equal(stream, streams.CARDS)
        drawn = drawn + 1

        if drawn == 1 then
            harness.equal(bound, 5)

            return 0
        end

        harness.equal(bound, 2097152)

        return 0
    end

    local original = iood.launch

    iood.launch = function(_, caster, dx, dy, power, target, stream)
        harness.equal(caster, player)
        harness.equal(power, 60)
        harness.equal(stream, streams.CARDS)
        launched[#launched + 1] = {
            dx = dx,
            dy = dy,
            target = target,
        }
    end

    local ok, message = pcall(function()
        orb.burst(owner, player, 1, 0, 60, streams.CARDS)
    end)

    iood.launch = original

    if not ok then
        error(message)
    end

    harness.equal(drawn, 2)
    harness.equal(#launched, 3)
    harness.equal(launched[1].dx, 0)
    harness.equal(launched[1].dy, 1)
    harness.equal(launched[1].target, rat)
    harness.equal(launched[3].target, rat)

    -- Without an aimed monster, empty cones pass false explicitly so the
    -- generic launch cannot acquire a cardinal adjacent actor by accident.
    drawn = 0
    launched = {}
    iood.launch = function(_, _, dx, dy, _, target)
        launched[#launched + 1] = {
            dx = dx,
            dy = dy,
            target = target,
        }
    end

    ok, message = pcall(function()
        orb.burst(owner, player, 0, -1, 60, streams.CARDS)
    end)

    iood.launch = original

    if not ok then
        error(message)
    end

    harness.equal(#launched, 3)
    harness.equal(launched[1].target, false)
    harness.equal(launched[2].target, rat)
    harness.equal(launched[3].target, false)
end

return test
