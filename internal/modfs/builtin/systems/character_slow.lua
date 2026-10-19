local component = require("constants.component")
local slow = require("policy.character.slow")

local system = {}

-- Theory of operation: The slow timer advances before the player cloud pass uses the next action delay.
-- Slow duration is reduced before player cloud exposure is evaluated.
function system.update(ctx, player, elapsed)
    slow.tick(ctx, player, elapsed)
end

register.system({
    id = "character.slow.tick",
    scope = "active",
    query = { component.PLAYER_SLOW },
    before = { "world.cloud.player_exposure" },
    update = system.update,
})

return system
