-- Banish is a player beam: visible aim, first ray contact, monster will,
-- and one existing Abyss actor transition after a successful contact.
local banish = require("policy.abilities.lugonu.banish")
local banishment = require("policy.combat.monster_hexes.banishment")
local component = require("constants.component")
local gods = require("constants.gods")
local harness = require("tests.harness")
local jobs = require("ids.jobs")
local monsters = require("ids.monsters")
local species = require("ids.species")
local fixture = require("tests.monster_ally_support_fixture")

local test = {}

-- A sparse floor still uses real ECS actor positions and the production
-- trajectory rule; the Abyss transaction is observed at its owner edge.
function test.run(ctx)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN,
        10, 10, 20)
    local target = fixture.actor(ctx, monsters.MONS_ORC,
        12, 10)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_ABYSSAL_KNIGHT,
        name = "Banish tester",
    })
    ctx:add(player, component.MAGIC, {
        current = 10,
        max = 10,
    })
    ctx:add(player, component.SKILLS, { entries = {} })
    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.LUGONU,
        piety = 200,
    })

    local game = fixture.context(ctx, player)
    local original = banishment.apply
    local banished = false

    function game:random(_, bound)
        return bound - 1
    end

    banishment.apply = function(_, caster, defender)
        harness.equal(caster, player)
        harness.equal(defender, target)
        banished = true
    end

    harness.truthy(banish.prepare(game, player, {
        dx = 0,
        dy = 0,
    }))
    harness.equal(banish.prepare(game, player, {
        dx = 2,
        dy = 0,
    }), nil)

    local okay, reason = pcall(banish.resolve, game, player, {
        dx = 2,
        dy = 0,
    })

    banishment.apply = original

    if not okay then
        error(reason)
    end

    harness.truthy(banished)
    harness.equal(ctx:get(player, component.MAGIC).current, 6)
    harness.truthy(ctx:get(player, component.RELIGION_WORSHIP).piety <
        200)
end

return test
