
local component = require("constants.component")
local harness = require("tests.harness")
local jobs = require("ids.jobs")
local mutations = require("ids.mutations")
local records = require("policy.mutations.records")
local species = require("ids.species")
local sublimation = require("policy.magic.effects.necromancy.sublimation")
local vampire = require("policy.character.vampire")

local test = {}

-- Bloodless Vampires cannot sublime blood.
function test.run(ctx)
    local player = ctx:create()

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_VAMPIRE,
        job_id = jobs.JOB_FIGHTER,
        name = "Blood spell test",
    })
    ctx:add(player, component.HEALTH, {
        current = 10,
        max = 20,
    })
    ctx:add(player, component.MAGIC, {
        current = 0,
        max = 5,
    })
    records.grant_innate(ctx, player, mutations.MUT_VAMPIRISM, 1)
    vampire.start(ctx, player)

    harness.falsy(sublimation.prepare(ctx, player),
        "living Vampires can sublime blood")

    local state = ctx:get(player, component.VAMPIRE)

    state.alive = false
    ctx:set(player, component.VAMPIRE, state)

    harness.truthy(sublimation.prepare(ctx, player),
        "bloodless Vampires cannot sublime blood")
end

return test
