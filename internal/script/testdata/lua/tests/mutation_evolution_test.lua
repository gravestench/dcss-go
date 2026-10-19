
local mutations = require("ids.mutations")
local species = require("ids.species")
local jobs = require("ids.jobs")
local classes = require("constants.mutation_classes")
local records = require("policy.mutations.records")
local evolution = require("policy.mutations.evolution")
local harness = require("tests.harness")

local test = {}

-- Evolution does not run before its source timer.
function test.run(ctx)
    harness.truthy(evolution.has_mutation(mutations.MUT_EVOLUTION),
        "Evolution is owned by the periodic mutation system")
    harness.truthy(evolution.has_mutation(mutations.MUT_DEVOLUTION),
        "Devolution is owned by the periodic mutation system")

    local player = ctx:create()

    ctx:add(player, "core.player", {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Evolution test",
    })
    ctx:add(player, "core.progression", {
        level = 1,
        total_xp = 0,
    })
    evolution.start(ctx, player)
    records.grant_acquired(ctx, player, mutations.MUT_EVOLUTION, 1)
    evolution.changed(ctx, player)

    local state = evolution.state(ctx, player)

    harness.equal(state.remaining_xp, 9,
        "Evolution starts at the next-level XP gap")
    harness.equal(state.mutations_gained, 0,
        "a new Evolution level resets the grant count")

    evolution.gain_experience(ctx, player, 10)
    state = evolution.state(ctx, player)

    harness.equal(state.remaining_xp, -1,
        "XP overshoot remains until the periodic check")

    evolution.tick(ctx, player, 199)
    harness.equal(evolution.state(ctx, player).remaining_xp, -1,
        "Evolution does not run before its source timer")

    evolution.tick(ctx, player, 1)
    state = evolution.state(ctx, player)

    harness.equal(state.remaining_xp, 9,
        "the periodic check discards surplus XP")
    harness.equal(state.mutations_gained, 1,
        "a successful periodic mutation counts toward consuming Evolution")

    -- The first zero draw chooses a one-level mutation. Choose a different
    -- eligible mutation on the second check so the test exercises two grants.
    local second_check = harness.random_context(ctx, { 0, 2 })

    evolution.gain_experience(ctx, player, 9)
    evolution.tick(second_check, player,
        state.next_check_aut - state.elapsed_aut)

    state = evolution.state(ctx, player)

    harness.equal(state.mutations_gained, 0,
        "two successful mutations consume one Evolution level")
    harness.equal(records.find(ctx, player, mutations.MUT_EVOLUTION), nil,
        "Evolution is removed after the second successful mutation")

    records.grant_acquired(ctx, player, mutations.MUT_DEVOLUTION, 1)
    evolution.changed(ctx, player)

    state = evolution.state(ctx, player)

    harness.equal(state.remaining_xp, 2,
        "Devolution uses one quarter of the next-level XP gap")
    harness.equal(state.mutations_gained, 0,
        "switching evolution direction resets the grant count")
end

return test
