-- Fake destruction visibly backlights a target; real destruction reaches
-- the ordinary explosion and damage owners instead of announcing a blast.
local component = require("constants.component")
local events = require("policy.religion.xom.events")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local ids = require("ids.xom_events")
local good = require("policy.religion.xom.selection_good")
local monsters = require("ids.monsters")
local status = require("policy.combat.monster_hexes.status")
local streams = require("constants.rng_streams")

local test = {}

-- The source chooses fake versus real only after the destruction chance
-- succeeds. Both outcomes must find an actual nearby target afterward.
local function destruction_gates(owner, player)
    local bounds = {
        3, 100, 100, 100, 100, 5, 5, 100,
        8, 100, 10, 8, 100, 100, 100, 3,
    }

    for _, expected in ipairs({
        {
            fake_roll = 0,
            event_id = ids.GOOD_FAKE_DESTRUCTION,
        },
        {
            fake_roll = 1,
            event_id = ids.GOOD_DESTRUCTION,
        },
    }) do
        local used = 0

        -- Keep every earlier good action out of this fixed selection.
        function owner:random(stream, bound)
            used = used + 1

            harness.equal(stream, streams.RELIGION)
            harness.equal(bound, bounds[used])

            if used == 12 or used == 15 then
                return 0
            end

            if used == 16 then
                return expected.fake_roll
            end

            return bound - 1
        end

        harness.equal(good.choose(owner, player, 100, 2,
            streams.RELIGION), expected.event_id)
        harness.equal(used, #bounds)
    end
end

-- Keep the source one-in-three skip out of this case. Combat's other
-- random rolls still go through their own ordinary stream.
function test.run(ctx)
    local player = ctx:create()
    local owner = fixture.context(ctx, player)
    local target = fixture.actor(ctx, monsters.MONS_ORC, 10, 7, 50)

    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 7,
        y = 7,
    })

    destruction_gates(owner, player)

    -- Xom's effect uses Religion RNG for the skip and damage rolls.
    function owner:random(stream, bound)
        if stream == streams.RELIGION then
            return bound == 3 and 1 or 0
        end

        return ctx:random(stream, bound)
    end

    harness.equal(events.apply(owner, player,
        ids.GOOD_FAKE_DESTRUCTION, 20, {
            stream = streams.RELIGION,
        }), 1)
    harness.truthy(status.backlit(ctx, target))

    local before = ctx:get(target, component.HEALTH).current

    harness.equal(events.apply(owner, player,
        ids.GOOD_DESTRUCTION, 20, {
            stream = streams.RELIGION,
        }), 1)
    harness.truthy(ctx:get(target, component.HEALTH).current < before)
end

return test
