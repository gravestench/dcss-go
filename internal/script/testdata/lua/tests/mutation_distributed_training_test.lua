local catalog = require("policy.catalog")
local component = require("constants.component")
local distributed = require("policy.character.distributed_training")
local harness = require("tests.harness")
local jobs = require("ids.jobs")
local mutations = require("ids.mutations")
local records = require("policy.mutations.records")
local skills = require("ids.skills")
local species_ids = require("ids.species")

local test = {}

function test.run(ctx)
    local player = ctx:create()
    local gnoll = catalog.get("species", species_ids.SP_GNOLL)

    ctx:add(player, component.PLAYER, {
        species_id = species_ids.SP_GNOLL,
        job_id = jobs.JOB_FIGHTER,
        name = "Distributed training test",
    })
    ctx:add(player, component.SKILLS, { entries = {} })
    ctx:add(player, component.SKILL_TRAINING, {
        available_xp = 0,
        spent_xp = 0,
        cost_level = 1,
        manual = false,
        settings = {},
        recent_practice = {},
        recent_all = {},
    })
    records.grant_innate(ctx, player,
        mutations.MUT_DISTRIBUTED_TRAINING, 1)
    records.grant_acquired(ctx, player, mutations.MUT_NO_DODGING, 1)
    distributed.activate(ctx, player)

    local entries = ctx:get(player, component.SKILLS).entries
    local training = ctx:get(player, component.SKILL_TRAINING)

    harness.equal(#entries, 28,
        "Gnoll training creates all current skills")
    harness.equal(#training.settings, 28,
        "each skill has a training setting")
    harness.truthy(training.manual,
        "Gnoll training is always manual")

    training.available_xp = 53

    harness.equal(distributed.spend(ctx, player, entries, training,
        gnoll), 0, "incomplete bundles do not spend XP")

    training.available_xp = 54

    harness.equal(distributed.spend(ctx, player, entries, training,
        gnoll), 54, "useless skills raise the cost of usable skills")

    for _, skill in ipairs(entries) do
        local expected = skill.id == skills.SK_DODGING and 0 or 1

        harness.equal(skill.points, expected,
            skill.id .. " receives its distributed share")
    end

    harness.equal(training.available_xp, 0,
        "the whole bundle consumes its XP")
end

return test
