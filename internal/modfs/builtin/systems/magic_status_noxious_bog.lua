local bog = require("policy.magic.effects.statuses.noxious_bog")
local system = {}

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
