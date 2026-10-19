local component = require("constants.component")
local attraction = require("policy.potions.attraction")

local system = {}

-- Theory of operation: The attraction status draws eligible monsters before recovery closes the action.
-- Attraction pulls eligible monsters after duration decay and before regeneration.
function system.update(ctx, player, aut)
    if player == ctx:player() then
        attraction.tick(ctx, player, aut)
    end
end

register.system({
    id = "status.potion_attraction",
    scope = "active",
    query = { component.PLAYER },
    after = { "status.duration" },
    before = { "status.regeneration" },
    update = system.update,
})

return system
