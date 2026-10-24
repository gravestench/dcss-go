-- Xom's potion action uses the normal saved duration owner; its weighted
-- choice must not consume an inventory item or create a second status path.
local component = require("constants.component")
local events = require("policy.religion.xom.events")
local event_ids = require("ids.xom_events")
local harness = require("tests.harness")
local items = require("ids.items")
local streams = require("constants.rng_streams")

local test = {}

-- Fix only Xom's choice roll. The ordinary potion owner still makes its
-- duration draw, proving the chosen effect executes instead of only logging.
local function might_choice(ctx)
    local player = ctx:create()

    ctx:add(player, component.DURATIONS, {
        might_aut = 0,
    })

    local wrapper = setmetatable({}, { __index = ctx })

    function wrapper:random(stream, bound)
        if stream == streams.RELIGION then
            harness.equal(bound, 76)

            return 40
        end

        return ctx:random(stream, bound)
    end

    local chosen = events.apply(wrapper, player,
        event_ids.GOOD_POTION, 40, {
            stream = streams.RELIGION,
        })

    harness.equal(chosen, items.POT_MIGHT)
    harness.truthy(ctx:get(player, component.DURATIONS).might_aut > 0)
end

-- Keep the test in the production catalog path used by both Xom entry points.
function test.run(ctx)
    might_choice(ctx)
end

return test
