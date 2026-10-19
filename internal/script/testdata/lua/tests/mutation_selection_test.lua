
local uses = require("constants.mutation_uses")
local mutations = require("ids.mutations")
local selection = require("policy.mutations.selection")
local choices = require("constants.mutation_choices")
local classes = require("constants.mutation_classes")
local species = require("ids.species")
local records = require("policy.mutations.records")
local harness = require("tests.harness")
local catalog = require("policy.catalog")

local test = {}

-- Check selected mutation pool membership without depending on draw order.
local function has_use(mutation_id, wanted)
    local definition = catalog.get("mutations", mutation_id)

    for _, use in ipairs(definition.uses) do
        if use == wanted then
            return true
        end
    end

    return false
end

-- Removed source mutation cannot be selected.
function test.run(ctx)
    -- The zero draw checks pool membership without coupling these rules to
    -- whichever definition happened to load first.
    harness.truthy(has_use(selection.weighted(ctx, uses.GOOD), uses.GOOD),
        "weighted good choice belongs to the good pool")
    harness.truthy(has_use(selection.weighted(ctx, uses.BAD), uses.BAD),
        "weighted bad choice belongs to the bad pool")
    harness.truthy(has_use(selection.weighted(ctx, uses.JIYVA), uses.JIYVA),
        "Jiyva uses its own unit-weight pool")
    harness.truthy(has_use(selection.weighted(ctx, uses.QAZLAL), uses.QAZLAL),
        "Qazlal uses its own unit-weight pool")

    local player = ctx:create()

    ctx:add(player, "core.player", {
        species_id = species.SP_HUMAN,
        job_id = "JOB_FIGHTER",
        name = "Mutation selection",
    })

    harness.truthy(has_use(selection.choose(ctx, player, choices.ANY,
        classes.ACQUIRED), uses.GOOD),
        "zero ratio draw chooses an eligible good mutation")
    harness.truthy(has_use(selection.choose(ctx, player, choices.BAD,
        classes.ACQUIRED), uses.BAD),
        "bad category chooses an eligible bad mutation")

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

    harness.truthy(has_use(selection.choose(weighted_xom, player,
        choices.XOM, classes.ACQUIRED), uses.XOM),
        "Xom substitution uses its unit-weight pool")

    local removable = ctx:create()

    records.grant_acquired(ctx, removable, mutations.MUT_STRONG, 1)
    records.grant_acquired(ctx, removable, mutations.MUT_FRAIL, 1)
    records.grant_acquired(ctx, removable, mutations.MUT_ROBUST, 1)
    records.grant_temporary(ctx, removable, mutations.MUT_SLOW, 1, 30)
    records.grant_innate(ctx, removable, mutations.MUT_HIGH_MAGIC, 1)

    local selected = selection.choose_removable(ctx, removable, choices.ANY)

    harness.truthy(selected == mutations.MUT_STRONG or
        selected == mutations.MUT_FRAIL or
        selected == mutations.MUT_ROBUST,
        "reservoir deletion selects an acquired mutation")
    harness.equal(selection.choose_removable(ctx, removable,
        choices.BAD), mutations.MUT_FRAIL,
        "bad deletion ignores good, innate, and temporary levels")
    harness.truthy(has_use(selection.choose_removable(ctx, removable,
        choices.GOOD), uses.GOOD),
        "good deletion filters by use without applying selection weights")
end

return test
