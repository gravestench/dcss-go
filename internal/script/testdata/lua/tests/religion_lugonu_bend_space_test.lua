-- Bend Space forces a player blink even through magical anchoring, then
-- gives an adjacent hostile monster a separate source coin flip.
local attitudes = require("constants.attitude")
local bend = require("policy.abilities.lugonu.bend_space")
local component = require("constants.component")
local gods = require("constants.gods")
local harness = require("tests.harness")
local jobs = require("ids.jobs")
local monsters = require("ids.monsters")
local species = require("ids.species")
local fixture = require("tests.monster_ally_support_fixture")

local test = {}

-- The fixture forwards real ECS and cloud operations while making the
-- source random landing deterministic enough to inspect both actors.
function test.run(ctx)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN,
        10, 10, 20)
    local hostile = fixture.actor(ctx, monsters.MONS_ORC,
        14, 10)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_ABYSSAL_KNIGHT,
        name = "Bend tester",
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
    ctx:add(player, component.HEX_STATUS, {
        anchor_aut = 30,
    })
    ctx:add(hostile, component.VAULT_ACTOR_OVERRIDES, {
        attitude = attitudes.HOSTILE,
    })

    local game = fixture.context(ctx, player)
    local axis = 0

    function game:records_at()
        return {}
    end

    function game:random(_, bound)
        if bound >= 100 then
            return bound - 1
        end

        if bound == 13 then
            axis = axis + 1

            return axis % 2 == 1 and 9 or 6
        end

        return 0
    end

    harness.equal(bend.prepare(game, player, {}), nil)
    bend.resolve(game, player)

    local player_position = ctx:get(player, component.POSITION)
    local hostile_position = ctx:get(hostile, component.POSITION)

    harness.equal(player_position.x, 13)
    harness.equal(player_position.y, 10)
    harness.truthy(hostile_position.x ~= 14 or
        hostile_position.y ~= 10)
    harness.equal(ctx:get(player, component.HEALTH).current, 18)
    harness.equal(ctx:get(player, component.MAGIC).current, 9)
end

return test
