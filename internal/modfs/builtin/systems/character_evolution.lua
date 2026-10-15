local evolution = require("policy.mutations.evolution")

local system = {}

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
