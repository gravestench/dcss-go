-- Theory of operation: the active player loses elapsed fear time after a
-- command. The source list is also checked each action, so dead or distant
-- monsters stop constraining movement without a hidden module cache.
-- Example: a player with one nearby fearmonger keeps the status after a
-- ten-aut move, while fear ends when that monster dies.
local component = require("constants.component")
local fear = require("policy.character.player_fear")

local system = {}

-- Visit only the acting player that owns fear, then let the policy update
-- its source references and remaining time together.
function system.update(ctx, actor, elapsed_aut)
    if actor == ctx:player() then
        fear.tick(ctx, actor, elapsed_aut)
    end
end

register.system({
    id = "character.player_fear.tick",
    scope = "active",
    query = { component.PLAYER_FEAR },
    after = { "status.duration" },
    before = { "status.regeneration" },
    update = system.update,
})

return system
