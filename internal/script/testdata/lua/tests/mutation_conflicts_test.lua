local conflicts = require("data.mutation_conflicts")
local outcomes = require("constants.mutation_conflict_outcomes")
local mutations = require("ids.mutations")
local harness = require("tests.harness")

local test = {}

function test.run()
    harness.equal(#conflicts, 32, "pinned source conflict row count")

    harness.equal(conflicts[2].first, mutations.MUT_REGENERATION,
        "first active conflict left ID")
    harness.equal(conflicts[2].second,
        mutations.MUT_INHIBITED_REGENERATION,
        "first active conflict right ID")
    harness.equal(conflicts[2].outcome, outcomes.IGNORE_UNLESS_FORCED,
        "first active conflict policy")

    harness.equal(conflicts[8].first, mutations.MUT_ROBUST,
        "Robust conflict position")
    harness.equal(conflicts[8].second, mutations.MUT_FRAIL,
        "Robust conflicts with Frail")
    harness.equal(conflicts[8].outcome, outcomes.TRADE_ONE,
        "Robust conflict trades one level")

    harness.equal(conflicts[32].first, mutations.MUT_HP_CASTING,
        "last conflict left ID")
    harness.equal(conflicts[32].second, mutations.MUT_LOW_MAGIC,
        "last conflict right ID")
    harness.equal(conflicts[32].outcome, outcomes.BLOCK_UNLESS_FORCED,
        "last conflict policy")
end

return test
