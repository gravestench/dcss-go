local component = require("constants.component")
local teleportitis = require("policy.mutations.effects.teleportitis")

local system = {}

-- Theory of operation: The policy uses the post-combat position and threat view to decide an involuntary move.
-- Teleportitis checks the player after combat and duration updates, using the current position.
function system.update(ctx, player, aut)
    if player == ctx:player() then
        teleportitis.tick(ctx, player, aut)
    end
end

register.system({
    id = "character.teleportitis",
    scope = "active",
    query = { component.PLAYER },
    after = { "attack.combat", "status.duration" },
    update = system.update,
})

return system
