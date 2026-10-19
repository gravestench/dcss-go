-- Theory of operation: each completed player action ages the saved Weak
-- timer by its actual aut cost, before the next melee decision reads it.
local weakness = require("policy.combat.player_weakness")

local system = {}

-- Only the player owns this timer; monster weakness has its own tick.
function system.update(ctx, actor, elapsed_aut)
    if actor == ctx:player() then
        weakness.tick(ctx, actor, elapsed_aut)
    end
end

register.system({
    id = "combat.player_weakness.tick",
    scope = "active",
    query = {},
    after = { "status.duration" },
    before = { "status.regeneration" },
    update = system.update,
})

return system
