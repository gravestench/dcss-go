local uses = require("constants.mutation_uses")
local mutations = require("ids.mutations")
local selection = require("policy.mutations.selection")
local choices = require("constants.mutation_choices")
local classes = require("constants.mutation_classes")
local species = require("ids.species")
local records = require("policy.mutations.records")
local harness = require("tests.harness")

local test = {}

function test.run(ctx)
    harness.equal(selection.weighted(ctx, uses.GOOD), mutations.MUT_STRONG,
        "first source-weighted good mutation")
    harness.equal(selection.weighted(ctx, uses.BAD),
        mutations.MUT_INHIBITED_REGENERATION,
        "first source-weighted bad mutation")
    harness.equal(selection.weighted(ctx, uses.JIYVA),
        mutations.MUT_GELATINOUS_BODY,
        "Jiyva selects by source order with unit weights")
    harness.equal(selection.weighted(ctx, uses.QAZLAL),
        mutations.MUT_HEAT_VULNERABILITY,
        "Qazlal selects by source order with unit weights")

    local player = ctx:create()

    ctx:add(player, "core.player", {
        species_id = species.SP_HUMAN,
        job_id = "JOB_FIGHTER",
        name = "Mutation selection",
    })

    harness.equal(selection.choose(ctx, player, choices.ANY,
        classes.ACQUIRED), mutations.MUT_STRONG,
        "source random mutation ratio selects good on a zero draw")
    harness.equal(selection.choose(ctx, player, choices.BAD,
        classes.ACQUIRED), mutations.MUT_INHIBITED_REGENERATION,
        "source bad category accepts first eligible mutation")

    harness.falsy(selection.accept(ctx, player,
        mutations.MUT_DEVOLUTION, classes.TEMPORARY, true),
        "Devolution cannot be temporary")
    harness.falsy(selection.accept(ctx, player,
        mutations.MUT_CARNIVOROUS, classes.ACQUIRED, true),
        "removed source mutation cannot be selected")

    local rare_xom = harness.random_context(ctx, { 0, 0 })

    harness.equal(selection.choose(rare_xom, player,
        choices.XOM, classes.ACQUIRED), nil,
        "Xom's one-in-a-thousand abort follows the enum draw")
    harness.equal(rare_xom:draws_used(), 2,
        "rare Xom abort consumes no later mutation draws")

    local raw_xom = harness.random_context(ctx, { 0, 1, 1, 0 })

    harness.equal(selection.choose(raw_xom, player,
        choices.XOM, classes.ACQUIRED), mutations.MUT_ANTENNAE,
        "ordinary Xom selection uses enum order and acceptance weight")

    local weighted_xom = harness.random_context(ctx, { 0, 1, 0, 0, 0 })

    harness.equal(selection.choose(weighted_xom, player,
        choices.XOM, classes.ACQUIRED), mutations.MUT_WEAK,
        "Xom substitution uses source table order and unit weights")

    local removable = ctx:create()

    records.grant_acquired(ctx, removable, mutations.MUT_STRONG, 1)
    records.grant_acquired(ctx, removable, mutations.MUT_FRAIL, 1)
    records.grant_acquired(ctx, removable, mutations.MUT_ROBUST, 1)
    records.grant_temporary(ctx, removable, mutations.MUT_SLOW, 1, 30)
    records.grant_innate(ctx, removable, mutations.MUT_HIGH_MAGIC, 1)

    harness.equal(selection.choose_removable(ctx, removable,
        choices.ANY), mutations.MUT_ROBUST,
        "reservoir deletion selects the last acquired source ID on zero draws")
    harness.equal(selection.choose_removable(ctx, removable,
        choices.BAD), mutations.MUT_FRAIL,
        "bad deletion ignores good, innate, and temporary levels")
    harness.equal(selection.choose_removable(ctx, removable,
        choices.GOOD), mutations.MUT_ROBUST,
        "good deletion filters by use without applying selection weights")
end

return test
