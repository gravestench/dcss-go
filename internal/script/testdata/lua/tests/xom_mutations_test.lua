-- Xom mutation actions must use saved mutation records and the shared
-- god-gift transition, so physiology and Zin still protect the player.
local component = require("constants.component")
local events = require("policy.religion.xom.events")
local event_ids = require("ids.xom_events")
local harness = require("tests.harness")
local records = require("policy.mutations.records")
local species = require("ids.species")
local streams = require("constants.rng_streams")

local test = {}

-- Each action receives its own character so ranks from the good pool do
-- not make the bad pool's effect look successful by accident.
local function player(ctx)
    local owner = ctx:create()

    ctx:add(owner, component.PLAYER, {
        species_id = species.SP_HUMAN,
    })
    ctx:add(owner, component.PROGRESSION, {
        level = 7,
    })

    return owner
end

-- Fix Xom's count and the ordinary mutation selection separately. This
-- catches a change that draws attempts from the wrong RNG owner.
local function fixed_draws(ctx)
    local wrapper = setmetatable({}, { __index = ctx })

    function wrapper:random(stream, bound)
        if stream == streams.RELIGION then
            harness.equal(bound, 4)

            return 0
        end

        if stream == streams.MUTATION then
            -- Xom's source one-in-1000 escape would return no candidate.
            if bound == 1000 then
                return 1
            end

            return 0
        end

        return ctx:random(stream, bound)
    end

    return wrapper
end

-- Both source pools reach a real Akara mutation record, not a transient
-- Xom-only flag or an announcement without a changed body.
local function both_pools(ctx)
    local draws = fixed_draws(ctx)

    for _, event_id in ipairs({
        event_ids.GOOD_MUTATION,
        event_ids.BAD_MUTATION,
    }) do
        local owner = player(ctx)
        local changed = events.apply(draws, owner, event_id, 30, {
            stream = streams.RELIGION,
        })

        harness.truthy(changed > 0,
            event_id .. " did not change a mutation rank")
        harness.truthy(#records.list(ctx, owner) > 0)
    end
end

-- The test uses the effective event definitions and production mutation owner.
function test.run(ctx)
    both_pools(ctx)
end

return test
