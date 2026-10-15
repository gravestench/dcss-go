local statuses = require("policy.magic.effects.statuses.player")
local system = {}

function system.update(ctx, actor, aut)
    if actor == ctx:player() then
        statuses.tick(ctx, actor, aut)
    end
end

register.system({
    id = "magic.player_status.tick",
    scope = "active",
    query = {},
    after = { "status.duration" },
    before = { "status.regeneration" },
    update = system.update,
})

return system
