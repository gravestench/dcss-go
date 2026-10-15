local classes = require("constants.mutation_classes")
local mutations = require("ids.mutations")
local records = require("policy.mutations.records")
local temporary = require("policy.mutations.temporary")
local harness = require("tests.harness")

local test = {}

local function remaining(ctx, player)
    local timer = ctx:get(player, "character.mutation_timer")

    return timer and timer.remaining_xp or nil
end

function test.run(ctx)
    local player = ctx:create()

    ctx:add(player, "core.progression", {
        level = 1,
        total_xp = 0,
    })

    records.grant_temporary(ctx, player,
        mutations.MUT_ROBUST, 1, 40)
    records.grant_temporary(ctx, player,
        mutations.MUT_CLEVER, 1, 30)

    harness.equal(remaining(ctx, player), 30,
        "a later temporary grant resets the shared countdown")
    harness.equal(records.find(ctx, player,
        mutations.MUT_ROBUST).state.temporary, 1,
        "the earlier temporary mutation keeps its level")

    records.delete(ctx, player,
        mutations.MUT_CLEVER, classes.TEMPORARY, 1)

    harness.equal(remaining(ctx, player), 30,
        "deleting one temporary mutation preserves the shared timer")

    temporary.gain_experience(ctx, player, 29)

    harness.equal(remaining(ctx, player), 1,
        "experience decrements the shared timer")

    temporary.gain_experience(ctx, player, 1)

    harness.equal(records.find(ctx, player, mutations.MUT_ROBUST), nil,
        "expiry removes the remaining temporary mutation")
    harness.equal(remaining(ctx, player), 0,
        "expiry clears the timer after the final temporary level")

    records.set_timer(ctx, player, 1)

    local valid_orphan = pcall(records.validate, ctx, player,
        { mutations = {} }, 1)

    harness.equal(valid_orphan, false,
        "restore rejects a running timer without temporary mutations")

    records.set_timer(ctx, player, 0)
end

return test
