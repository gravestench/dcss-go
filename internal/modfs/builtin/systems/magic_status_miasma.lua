local rot = require("policy.magic.effects.statuses.corpse_rot")
local system = {}

function system.update(ctx, actor)
    rot.tick(ctx, actor)
end

register.system({
    id = "magic.status.miasma.tick",
    scope = "active",
    query = {},
    before = { "monster.decision" },
    update = system.update,
})

return system
