-- Power Leap commits one exact landing cell and strikes nearby enemies.
-- The source rejects canceled, occupied, or too-distant targets for free.
local abilities = require("ids.abilities")
local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local gods = require("constants.gods")
local harness = require("tests.harness")
local jobs = require("ids.jobs")
local monsters = require("ids.monsters")
local registry = require("policy.abilities.registry")
local species = require("ids.species")

local test = {}

-- Reuse the shared sparse floor fixture for real ECS occupancy and movement.
function test.run(ctx)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN,
        10, 10, 30)
    local foe = fixture.actor(ctx, monsters.MONS_ORC,
        12, 11, 50)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Leap tester",
    })
    ctx:add(player, component.PROGRESSION, {
        level = 10,
        total_xp = 3910,
        pending_stat_level = 0,
    })
    ctx:add(player, component.MAGIC, {
        current = 10,
        max = 10,
    })
    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.RU,
        piety = 100,
    })

    local game = fixture.context(ctx, player)
    local leap = registry.get(abilities.RU_POWER_LEAP)

    harness.truthy(leap ~= nil)
    local worship = ctx:get(player, component.RELIGION_WORSHIP)

    worship.piety = 99
    ctx:set(player, component.RELIGION_WORSHIP, worship)
    harness.truthy(not registry.usable_now(game, player, leap))
    worship.piety = 100
    ctx:set(player, component.RELIGION_WORSHIP, worship)

    harness.truthy(registry.usable_now(game, player, leap))
    harness.truthy(leap.prepare(game, player, {
        dx = 0,
        dy = 0,
    }) ~= nil)
    harness.truthy(leap.prepare(game, player, {
        dx = 4,
        dy = 0,
    }) ~= nil)
    harness.truthy(leap.prepare(game, player, {
        dx = 2,
        dy = 1,
    }) ~= nil)
    harness.equal(ctx:get(player, component.MAGIC).current, 10)

    local choice = leap.prepare(game, player, {
        dx = 2,
        dy = 0,
    })

    harness.equal(choice, nil)
    leap.resolve(game, player, {
        dx = 2,
        dy = 0,
    }, 10)

    local landing = ctx:get(player, component.POSITION)
    local exhausted = ctx:get(player, component.PLAYER_EXHAUSTION)

    harness.equal(landing.x, 12)
    harness.equal(landing.y, 10)
    harness.equal(ctx:get(player, component.MAGIC).current, 5)
    harness.truthy(ctx:get(foe, component.HEALTH).current < 50)
    harness.truthy(exhausted.remaining_aut >= 180 and
        exhausted.remaining_aut <= 250)

    -- A constrictor can stop a committed leap. That failure still pays
    -- five MP and exhaustion, while the target cell remains untouched.
    ctx:remove(player, component.PLAYER_EXHAUSTION)

    local constrictor = fixture.actor(ctx, monsters.MONS_ORC,
        11, 10, 50)

    ctx:add(player, component.CONSTRICTION, {
        by = constrictor,
        escape_attempts = 0,
    })

    function game:random(_, bound)
        if bound == 13 then
            return 0
        end

        return bound - 1
    end

    leap.resolve(game, player, {
        dx = 1,
        dy = 0,
    }, 10)

    landing = ctx:get(player, component.POSITION)

    harness.equal(landing.x, 12)
    harness.equal(ctx:get(player, component.MAGIC).current, 0)
    harness.truthy(ctx:has(player, component.CONSTRICTION))
    harness.truthy(ctx:has(player, component.PLAYER_EXHAUSTION))
end

return test
