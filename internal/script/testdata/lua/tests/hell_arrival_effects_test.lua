-- Hell arrival rolls are replayable through one named stream. This test
-- checks source draw order and protection before the live effects run.
local effects = require("policy.world.hell.effects")
local kinds = require("constants.hell_effects")
local gods = require("constants.gods")
local harness = require("tests.harness")
local messages = require("data.hell_effect_messages")
local streams = require("constants.rng_streams")

local test = {}

-- Reject extra or reordered draws so an unrelated message change cannot
-- silently alter the selected gameplay consequence.
local function rolls(expected)
    local ctx = {}
    local used = 0

    function ctx:random(stream, bound)
        used = used + 1
        local next_draw = expected[used]

        harness.equal(stream, streams.HELL_EFFECT)
        harness.truthy(next_draw, "unexpected Hell effect draw")
        harness.equal(bound, next_draw.bound)

        return next_draw.value
    end

    function ctx:used()
        return used
    end

    return ctx
end

-- Zin's source passive protects before a message or outcome is drawn.
local function protected_zin()
    local ctx = rolls({
        { bound = 400, value = 0 },
    })
    local plan = effects.plan(ctx, {
        god_id = gods.ZIN,
        piety = 200,
    }, false)

    harness.truthy(plan.protected)
    harness.equal(ctx:used(), 1)

    local unprotected = rolls({
        { bound = 400, value = 200 },
        { bound = 6, value = 1 },
        { bound = #messages.quiet, value = 0 },
        { bound = 4, value = 3 },
    })
    local other = effects.plan(unprotected, {
        god_id = gods.ZIN,
        piety = 200,
    }, false)

    harness.falsy(other.protected)
    harness.equal(unprotected:used(), 4)
end

-- The loudness draw happens even in Silence, then a quiet line is chosen.
local function silenced_arrival()
    local ctx = rolls({
        { bound = 6, value = 0 },
        { bound = #messages.quiet, value = 0 },
        { bound = 4, value = 1 },
    })
    local plan = effects.plan(ctx, {
        god_id = gods.NO_GOD,
        piety = 0,
    }, true)

    harness.falsy(plan.loud)
    harness.equal(plan.message, messages.quiet[1])
    harness.equal(plan.outcome, kinds.DRAIN)
    harness.equal(ctx:used(), 3)

    local without_smell = rolls({
        { bound = 6, value = 1 },
        { bound = #messages.quiet, value = 0 },
        { bound = 4, value = 3 },
    })
    local no_smell_plan = effects.plan(without_smell, {
        god_id = gods.NO_GOD,
        piety = 0,
    }, false, false)

    harness.equal(no_smell_plan.message, messages.no_smell)
end

-- Every source outcome occupies one of four equal slots, including the
-- quiet message with no further punishment.
local function outcomes()
    local expected = {
        kinds.BAD_MUTATION,
        kinds.DRAIN,
        kinds.STAT_LOSS,
        kinds.NONE,
    }

    for outcome = 0, 3 do
        local ctx = rolls({
            { bound = 6, value = 1 },
            { bound = #messages.quiet, value = 0 },
            { bound = 4, value = outcome },
        })
        local plan = effects.plan(ctx, {
            god_id = gods.NO_GOD,
            piety = 0,
        }, false)

        harness.falsy(plan.loud)
        harness.equal(plan.outcome, expected[outcome + 1])
        harness.equal(ctx:used(), 3)
    end
end

-- A loud result uses the separate source line group.
local function loud_arrival()
    local ctx = rolls({
        { bound = 6, value = 0 },
        { bound = #messages.noisy, value = 1 },
        { bound = 4, value = 2 },
    })
    local plan = effects.plan(ctx, {
        god_id = gods.NO_GOD,
        piety = 0,
    }, false)

    harness.truthy(plan.loud)
    harness.equal(plan.message, messages.noisy[2])
    harness.equal(plan.outcome, kinds.STAT_LOSS)
end

function test.run()
    protected_zin()
    silenced_arrival()
    outcomes()
    loud_arrival()
end

return test
