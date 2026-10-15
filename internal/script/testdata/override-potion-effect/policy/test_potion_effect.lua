local items = require("ids.items")
local potions = require("policy.potions")

local policy = {}

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
