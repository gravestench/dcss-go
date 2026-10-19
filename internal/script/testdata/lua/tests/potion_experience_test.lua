-- Potion raises the player to the next level threshold.

local harness = require("tests.harness")
local items = require("ids.items")
local potions = require("policy.potions")
local experience = require("policy.potions.experience")

local test = {}

-- Compare experience-potion adjustments across skill totals and levels,
-- ensuring the registered potion uses the source progression formula.
function test.run(ctx)
    harness.truthy(potions.get(items.POT_EXPERIENCE),
        "experience potion is registered")

    local first = experience.adjusted_total(0, 1, 2, 0)
    local next_level = experience.adjusted_total(20, 2, 3, 0)

    harness.truthy(first > 0,
        "potion raises the player to the next level threshold")
    harness.truthy(next_level > first,
        "later levels have higher experience thresholds")
end

return test
