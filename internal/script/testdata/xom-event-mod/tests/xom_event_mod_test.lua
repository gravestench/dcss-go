-- A sparse layer adds events between source gates with stable-ID ties.
local bad = require("policy.religion.xom.selection_bad")
local events = require("policy.religion.xom.events")
local good = require("policy.religion.xom.selection_good")
local harness = require("tests.harness")
local ids = require("ids.xom_mod_events")
local source_ids = require("ids.xom_events")
local streams = require("constants.rng_streams")

local test = {}

-- Fail if an added event changes any draw before its declared stage.
local function fixed_draws(ctx, bounds)
    local used = 0
    local proxy = setmetatable({}, { __index = ctx })

    function proxy:random(stream, bound)
        used = used + 1
        harness.equal(stream, streams.RELIGION)
        harness.equal(bound, bounds[used])

        return bound - 1
    end

    function proxy:draws_used()
        return used
    end

    return proxy
end

-- The first source good gate fails and the first custom tie rejects.
local function good_extension(ctx)
    local proxy = fixed_draws(ctx, { 3 })

    harness.equal(good.choose(proxy, nil, 20, 1,
        streams.RELIGION), ids.SECOND)
    harness.equal(proxy:draws_used(), 1)
end

-- Both early bad source gates fail before the custom stage succeeds.
local function bad_extension(ctx)
    local proxy = fixed_draws(ctx, { 4, 2 })
    local state = { gift_timeout = 10 }

    harness.equal(bad.choose(proxy, nil, state, 4, 0,
        streams.RELIGION), ids.BAD)
    harness.equal(proxy:draws_used(), 2)
end

-- Exercise the production selectors against the effective layered catalog.
function test.run(ctx)
    local replaced, effect = events.get(source_ids.BAD_NOISE)

    harness.equal(replaced.name, "Modified noise")
    harness.equal(replaced.badness_10x, 70)
    harness.truthy(effect.apply(ctx, nil, source_ids.BAD_NOISE))

    good_extension(ctx)
    bad_extension(ctx)
end

return test
