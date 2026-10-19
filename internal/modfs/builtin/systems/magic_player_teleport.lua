local teleport = require("policy.magic.player_teleport")

local system = {}

-- Theory of operation: A scroll-created teleport may resolve before the generic duration pass decrements it.
-- Pending teleportation resolves after scroll reading and before status durations age.
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
