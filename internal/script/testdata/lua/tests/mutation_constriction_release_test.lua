local component = require("constants.component")
local jobs = require("ids.jobs")
local species = require("ids.species")
local revivification = require("policy.magic.effects.necromancy.revivification")
local statuses = require("policy.magic.effects.statuses.player")
local harness = require("tests.harness")

local test = {}

function test.run(ctx)
    local player = ctx:create()
    local monster = ctx:create()

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Grip release test",
    })
    ctx:add(player, component.PROGRESSION, {
        level = 1,
    })
    ctx:add(player, component.SKILLS, {
        entries = {},
    })
    ctx:add(player, component.HEALTH, {
        current = 5,
        max = 15,
    })
    ctx:add(player, component.REGENERATION, {
        hp_progress = 0,
        mp_progress = 0,
    })

    local status = statuses.ensure(ctx, player)

    status.death_door_aut = 100
    status.death_door_hp = 3
    ctx:add(player, component.PLAYER_STATUS, status)
    ctx:add(monster, component.PLAYER_CONSTRICTION, {
        by = player,
        held_aut = 10,
        escape_attempts = 0,
    })

    revivification.resolve(ctx, player, nil, nil, 100)

    harness.truthy(ctx:has(player, component.PLAYER_PARALYSIS),
        "aborting Death's Door paralyses the player")
    harness.falsy(ctx:has(monster, component.PLAYER_CONSTRICTION),
        "source paralysis releases direct player grips")
end

return test
