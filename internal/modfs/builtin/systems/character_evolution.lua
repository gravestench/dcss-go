local evolution = require("policy.mutations.evolution")

local system = {}

-- Theory of operation: The policy spends the mutation timer on the player after ordinary duration bookkeeping.
-- Evolution's experience timer advances after ordinary status durations for the player.
function system.update(ctx, player, aut)
    evolution.tick(ctx, player, aut)
end

register.system({
    id = "character.evolution",
    scope = "active",
    query = { "core.player", "character.evolution" },
    after = { "status.duration" },
    update = system.update,
})

return system
