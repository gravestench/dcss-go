-- The probe invokes the overlaid curing effect through the normal registry.
-- Example: test.potion_effect returns the overlaid curing message.

local items = require("ids.items")
local potions = require("policy.potions")

local policy = {}

-- Invoke curing through the shared registry and return its message, proving
-- call sites see the overlaid effect without any adapter or special case.
function policy.run(ctx)
    return {
        message = potions.get(items.POT_CURING).apply(ctx, nil),
    }
end

register.policy({
    id = "test.potion_effect",
    run = policy.run,
})

return policy
