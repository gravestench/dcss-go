local component = require("constants.component")
local agility = require("policy.character.agility")

local system = {}

-- Theory of operation: The tick removes expired agility before regeneration observes the player status set.
-- Agility duration ticks after the general status pass and before regeneration.
function system.update(ctx, actor, aut)
    agility.tick(ctx, actor, aut)
end

register.system({
    id = "status.agility",
    scope = "active",
    query = { component.PLAYER, component.AGILITY },
    after = { "status.duration" },
    before = { "status.regeneration" },
    update = system.update,
})

return system
