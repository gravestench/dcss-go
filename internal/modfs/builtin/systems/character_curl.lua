local component = require("constants.component")
local curl = require("policy.character.curl")

local system = {}

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
