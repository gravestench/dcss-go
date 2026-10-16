local teleport = require("policy.magic.player_teleport")

local system = {}

function system.update(ctx, actor, aut)
    if actor == ctx:player() then
        teleport.tick(ctx, actor, aut)
    end
end

register.system({
    id = "magic.player_teleport.tick",
    scope = "active",
    query = {},
    after = { "item.read" },
    before = { "status.duration" },
    update = system.update,
})

return system
