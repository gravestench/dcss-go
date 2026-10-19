local statuses = require("policy.magic.effects.statuses.player")
local system = {}

-- Theory of operation: Player spell statuses are aged before regeneration samples them.
-- Player spell statuses tick after general durations and before regeneration.
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
