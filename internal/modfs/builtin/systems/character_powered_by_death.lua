local component = require("constants.component")
local powered = require("policy.character.powered_by_death")

local system = {}

-- Theory of operation: Stack timers are spent before their regeneration bonus is sampled.
-- Powered-by-death stacks age after duration decay, before the next regeneration pass.
function system.update(ctx, player, aut)
    powered.tick(ctx, player, aut)
end

register.system({
    id = "status.powered_by_death",
    scope = "active",
    query = { component.PLAYER, component.POWERED_BY_DEATH },
    after = { "status.duration" },
    before = { "status.regeneration" },
    update = system.update,
})

return system
