-- The weapon-class override forces plus four on generated weapons while retaining normal eligibility.
-- Example: rolling WPN_TEST_SPROCKET through this class writes result.plus = 4.

local catalog = require("policy.item_generation.catalog")
local classes = require("ids.object_classes")

local policy = {}

-- Keep normal random weapon eligibility in the overlay so the test changes
-- only roll behavior, not which item definitions can enter the class pool.
function policy.eligible(_, definition)
    return definition.class == classes.OBJ_WEAPONS and
        definition.generation.mode == "random"
end

-- Reuse the definition's authored weight to isolate the overridden roll from
-- selection probability.
function policy.weight(_, definition)
    return definition.generation.weight or 1
end

-- Force a distinctive plus value on the mutable roll result, making policy
-- replacement visible without needing to materialize an item.
function policy.roll(_, _, _, result)
    result.plus = 4
end

catalog.register(classes.OBJ_WEAPONS, policy)

return policy
