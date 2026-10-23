-- One player-time system advances the saved god clock after an action.
-- The policy owns piety and worship changes; this registration only connects
-- the scheduler's elapsed aut to that player-owned rule.
local component = require("constants.component")
local upkeep = require("policy.religion.upkeep")

local system = {}

-- Monster actions cannot run the player's periodic devotion checks.
function system.update(ctx, actor, elapsed_aut)
    if actor == ctx:player() then
        upkeep.tick(ctx, actor, elapsed_aut)
    end
end

register.system({
    id = "religion.upkeep",
    scope = "active",
    query = { component.PLAYER },
    after = { "religion.prayer" },
    update = system.update,
})

return system
