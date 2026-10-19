local component = require("constants.component")
local curl = require("policy.character.curl")

local system = {}

-- Theory of operation: The reset clears the defensive curl only after combat has used it for the finished exchange.
-- Curling resets after combat so the defense bonus can cover the attack that just landed.
function system.update(ctx, player)
    curl.reset(ctx, player)
end

-- Source: main.cc:_uncurl runs after the player's action and before
-- world_reacts allows monsters to take their next actions.
register.system({
    id = "status.curl.reset",
    scope = "active",
    query = { component.PLAYER, component.CURL },
    after = { "attack.combat" },
    before = { "status.duration" },
    update = system.update,
})

return system
