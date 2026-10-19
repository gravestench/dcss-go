-- Class weights and depth adjustments retain their source boundaries across random draws.

local streams = require("constants.rng_streams")
local catalog = require("policy.catalog")
local choice = require("policy.item_generation.class_choice")
local classes = require("ids.object_classes")
local harness = require("tests.harness")
local policies = require("policy.item_generation.catalog")
local quality = require("constants.vault_item_quality")

local test = {}

-- Scripted rolls pin the exact class-weight boundaries under one RNG stream.
local function draw_context(draws)
    local context = {
        draws = draws,
        index = 0,
    }

    -- Replay explicit class-selection draws and validate their bounds so
    -- weighted boundary cases cannot pass after a pool shape changes.
    function context:random(stream, bound)
        self.index = self.index + 1
        local draw = self.draws[self.index]

        harness.equal(stream, streams.ITEM_GENERATION, "named item RNG stream")
        harness.equal(bound, draw.bound, "source draw bound")

        return draw.value
    end

    return context
end

-- First and last entries in ordinary and superb class tables catch fenceposts.
local function class_weight_boundaries()
    local first = draw_context({
        {
            bound = 1720,
            value = 0,
        },
    })
    local last = draw_context({
        {
            bound = 1720,
            value = 1719,
        },
    })
    local superb_first = draw_context({
        {
            bound = 70,
            value = 0,
        },
    })
    local superb_last = draw_context({
        {
            bound = 70,
            value = 69,
        },
    })

    harness.equal(choice.pick(first, {
        depth = 1,
        quality = quality.ORDINARY,
    }), classes.OBJ_STAVES, "first ordinary class")

    harness.equal(choice.pick(last, {
        depth = 1,
        quality = quality.ORDINARY,
    }), classes.OBJ_GOLD, "last ordinary class")

    harness.equal(choice.pick(superb_first, {
        depth = 1,
        quality = quality.SUPERB,
    }), classes.OBJ_WEAPONS, "first superb class")

    harness.equal(choice.pick(superb_last, {
        depth = 1,
        quality = quality.SUPERB,
    }), classes.OBJ_MISCELLANY, "last superb class")
end

-- Early-game wand fallback and deep miscellaneous chance use different gates.
local function depth_adjustments()
    local early_wand = draw_context({
        {
            bound = 1720,
            value = 100,
        },
        {
            bound = 7,
            value = 1,
        },
        {
            bound = 2,
            value = 0,
        },
    })
    local deep_misc = draw_context({
        {
            bound = 1720,
            value = 0,
        },
        {
            bound = 5000,
            value = 0,
        },
    })

    harness.equal(choice.pick(early_wand, {
        depth = 1,
        quality = quality.ORDINARY,
    }), classes.OBJ_POTIONS, "early wand becomes potion")

    harness.equal(choice.pick(deep_misc, {
        depth = 8,
        quality = quality.ORDINARY,
    }), classes.OBJ_MISCELLANY, "deep misc chance")
end

-- A catalog class cannot be offered by random generation without a handler.
local function every_random_class_has_a_policy()
    local seen = {}

    for _, definition in ipairs(catalog.all("items")) do
        if definition.generation.mode == "random" then
            seen[definition.class] = true
        end
    end

    for class_id in pairs(seen) do
        harness.truthy(policies.policy(class_id),
            "missing class policy " .. class_id)
    end
end

-- Check class weights, depth gates, and handler coverage together; a random
-- class is only usable when all three parts agree.
function test.run()
    class_weight_boundaries()
    depth_adjustments()
    every_random_class_has_a_policy()
end

return test
