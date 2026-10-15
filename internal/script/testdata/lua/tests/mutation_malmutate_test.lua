local harness = require("tests.harness")
local mutations = require("ids.mutations")
local species = require("ids.species")
local records = require("policy.mutations.records")
local malmutate = require("policy.mutations.malmutate")
local attributes = require("policy.character.attributes")
local stat_loss_policy = require("policy.character.stat_loss")
local catalog = require("policy.catalog")

local test = {}

local function player(ctx)
    local owner = ctx:create()

    ctx:add(owner, "core.player", {
        species_id = species.SP_HUMAN,
        job_id = "JOB_FIGHTER",
        name = "Malmutation test",
    })

    return owner
end

function test.run(ctx)
    local resistant = player(ctx)

    records.grant_acquired(ctx, resistant,
        mutations.MUT_MUTATION_RESISTANCE, 1)

    local draws = harness.random_context(ctx, { 1, 0, 0 })
    local result = malmutate.apply(draws, resistant, "test beam")

    harness.equal(result.kind, "granted",
        "a resisted-but-passing malmutation grants the selected mutation")
    harness.equal(result.mutation_id,
        mutations.MUT_INHIBITED_REGENERATION,
        "four-in-five malmutation quality selects a bad mutation")
    harness.equal(draws:draws_used(), 3,
        "quality and resistance each roll once before weighted selection")

    local fully_resistant = player(ctx)

    records.grant_acquired(ctx, fully_resistant,
        mutations.MUT_MUTATION_RESISTANCE, 3)

    local stopped_draws = harness.random_context(ctx, { 1 })
    local stopped = malmutate.apply(stopped_draws, fully_resistant,
        "test beam")

    harness.equal(stopped.kind, "resisted",
        "maximum mutation resistance blocks malmutation")
    harness.equal(stopped_draws:draws_used(), 1,
        "source quality roll occurs before an automatic resistance block")

    local mummy = player(ctx)

    ctx:set(mummy, "core.player", {
        species_id = species.SP_MUMMY,
        job_id = "JOB_FIGHTER",
        name = "Malmutation test",
    })
    ctx:add(mummy, "core.attributes", {
        strength = 10,
        intelligence = 10,
        dexterity = 10,
    })

    local decay_draws = harness.random_context(ctx, { 1, 0, 0 })
    local decayed = malmutate.apply(decay_draws, mummy, "test beam")
    local stat_loss = ctx:get(mummy, "character.stat_loss")

    harness.equal(decayed.kind, "decomposed",
        "unsafe undead malmutation decomposes instead of granting a level")
    harness.equal(stat_loss.strength, 1,
        "decomposition drains the randomly selected stat")
    harness.equal(stat_loss.remaining_xp, 30,
        "first stat loss starts the source recovery roll")
    harness.equal(attributes.current(ctx, mummy).strength, 9,
        "decomposed stat loss affects current attributes")
    harness.equal(decay_draws:draws_used(), 3,
        "decomposition draws a stat and recovery timer after quality")

    stat_loss_policy.gain_experience(decay_draws, mummy, 10, 1)

    harness.equal(ctx:get(mummy, "character.stat_loss").remaining_xp, 15,
        "experience advances the shared stat recovery timer")

    stat_loss_policy.gain_experience(decay_draws, mummy, 10, 1)

    harness.equal(stat_loss_policy.amount(ctx, mummy, "strength"), 0,
        "experience restores a drained stat when the timer expires")
    harness.equal(ctx:get(mummy, "character.stat_loss").remaining_xp, 0,
        "the recovery timer clears after every stat is restored")
    harness.equal(attributes.current(ctx, mummy).strength, 10,
        "restored stat loss stops affecting current attributes")
    harness.equal(decay_draws:draws_used(), 3,
        "source reservoir of one does not advance the random stream")

    local deeply_drained = player(ctx)

    ctx:add(deeply_drained, "core.attributes", {
        strength = 10,
        intelligence = 10,
        dexterity = 10,
    })
    ctx:add(deeply_drained, "character.stat_loss", {
        strength = 20,
        intelligence = 0,
        dexterity = 0,
        remaining_xp = 1,
    })

    local deep_draws = harness.random_context(ctx, { 4, 0 })

    stat_loss_policy.gain_experience(deep_draws, deeply_drained, 1, 1)

    harness.equal(stat_loss_policy.amount(ctx, deeply_drained,
        "strength"), 15,
        "a stat below zero gains extra source recovery points")
    harness.equal(ctx:get(deeply_drained,
        "character.stat_loss").remaining_xp, 30,
        "remaining deep drain starts another recovery roll")
    harness.equal(deep_draws:draws_used(), 2,
        "deep recovery draws its bonus before the next timer")

    local heavily_mutated = player(ctx)
    local granted = 0
    local eligible = 0

    for _, id in ipairs({
        mutations.MUT_STRONG,
        mutations.MUT_CLEVER,
        mutations.MUT_AGILE,
        mutations.MUT_ROBUST,
        mutations.MUT_FRAIL,
        mutations.MUT_HIGH_MAGIC,
        mutations.MUT_LOW_MAGIC,
        mutations.MUT_FAST,
        mutations.MUT_SLOW,
        mutations.MUT_WILD_MAGIC,
    }) do
        local definition = catalog.get("mutations", id)
        local amount = math.min(definition.max_level, 15 - granted)

        if amount > 0 then
            records.grant_acquired(ctx, heavily_mutated, id, amount)
            granted = granted + amount
            eligible = eligible + 1
        end
    end

    harness.equal(granted, 15, "heavy mutation fixture reaches source cap")

    local loss_draws = harness.random_context(ctx, {
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    })
    local lost = malmutate.apply(loss_draws, heavily_mutated, "test beam")
    local remaining = 0

    for _, entry in ipairs(records.list(ctx, heavily_mutated)) do
        remaining = remaining + entry.state.acquired
    end

    harness.equal(lost.kind, "removed",
        "a heavily mutated player can lose an acquired level")
    harness.equal(remaining, 14,
        "heavy malmutation loss removes exactly one level")
    harness.equal(loss_draws:draws_used(), eligible + 1,
        "heavy loss skips the saturated chance and the first reservoir roll")
end

return test
