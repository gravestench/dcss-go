local bog = require("policy.magic.effects.statuses.noxious_bog")
local system = {}

-- Theory of operation: The bog component ages before monsters choose a route across terrain.
-- Noxious bog status is advanced before monsters decide where to move.
function system.update(ctx, actor, aut)
    bog.tick(ctx, actor, aut)
end

register.system({
    id = "magic.status.noxious_bog.tick",
    scope = "active",
    query = {},
    before = { "monster.decision" },
    update = system.update,
})

return system
