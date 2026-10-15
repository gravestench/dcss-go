local component = require("constants.component")
local jobs = require("ids.jobs")
local mutations = require("ids.mutations")
local species = require("ids.species")
local extra_lives = require("policy.character.extra_lives")
local formulas = require("policy.character.formulas")
local catalog = require("policy.catalog")
local records = require("policy.mutations.records")
local harness = require("tests.harness")

local test = {}

function test.run(ctx)
    local player = ctx:create()

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_FELID,
        job_id = jobs.JOB_FIGHTER,
        name = "Extra lives test",
    })
    ctx:add(player, component.PROGRESSION, {
        level = 1,
        total_xp = 0,
    })
    ctx:add(player, component.HEALTH, {
        current = 20,
        max = 20,
    })
    records.grant_innate(ctx, player, mutations.MUT_MULTILIVED, 1)
    extra_lives.start(ctx, player)

    harness.equal(extra_lives.state(ctx, player).lives, 0,
        "Felids begin with no extra lives")

    extra_lives.on_level(ctx, player, 4)
    harness.equal(extra_lives.state(ctx, player).lives, 1,
        "Felids gain their first extra life at XL4")

    extra_lives.on_level(ctx, player, 7)
    extra_lives.on_level(ctx, player, 10)
    harness.equal(extra_lives.state(ctx, player).lives, 2,
        "Felids can hold at most two extra lives")

    harness.truthy(extra_lives.on_lethal(ctx, player),
        "a fatal hit can spend a stocked Felid life")

    local spent = extra_lives.state(ctx, player)

    harness.equal(spent.lives, 1,
        "the death consumes exactly one life")
    harness.equal(spent.deaths, 1,
        "the death increments the persistent death count")
    harness.truthy(spent.pending_revival,
        "death remains pending until the next input boundary")

    extra_lives.on_level(ctx, player, 11)
    harness.equal(extra_lives.state(ctx, player).lives, 2,
        "a missed threshold awards a life at the next XL after a death")

    local capped = extra_lives.state(ctx, player)

    capped.max_level = 27
    capped.lives = 0
    capped.deaths = 8
    capped.pending_revival = false
    ctx:set(player, component.EXTRA_LIVES, capped)

    local progress = ctx:get(player, component.PROGRESSION)

    progress.level = 27
    local felid = catalog.get("species", species.SP_FELID)

    progress.total_xp = formulas.experience_needed(28, felid.xp)
    ctx:set(player, component.PROGRESSION, progress)
    harness.equal(ctx:get(player, component.PROGRESSION).total_xp,
        formulas.experience_needed(28, felid.xp),
        "the test player has the XL28 experience threshold")
    harness.equal(extra_lives.state(ctx, player).max_level, 27,
        "the test player begins at historical XL27")
    extra_lives.on_experience(ctx, player)

    local beyond = extra_lives.state(ctx, player)

    harness.equal(beyond.max_level, 28,
        "historical XL grows beyond the playable XL27 cap")
    harness.equal(beyond.lives, 1,
        "continued experience can replenish a spent life after XL27")
end

return test
