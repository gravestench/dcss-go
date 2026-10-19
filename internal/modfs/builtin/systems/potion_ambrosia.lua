local component = require("constants.component")
local ambrosia = require("policy.potions.ambrosia")

local system = {}

-- Theory of operation: Confusion is aged first; ambrosia then restores resources before ordinary regeneration.
-- Ambrosia restores resources after confusion ticks and before ordinary regeneration.
function system.update(ctx, player, aut)
    if player == ctx:player() then
        ambrosia.tick(ctx, player, aut)
    end
end

register.system({
    id = "status.potion_ambrosia",
    scope = "active",
    query = { component.PLAYER },
    after = { "zap.player_confusion.tick" },
    before = { "status.regeneration" },
    update = system.update,
})

return system
