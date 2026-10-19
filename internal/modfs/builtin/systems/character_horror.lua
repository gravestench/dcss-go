local component = require("constants.component")
local horror = require("policy.character.horror_threat")

local system = {}

-- Theory of operation: Visible threats determine a fresh horror penalty before resource recovery uses that penalty.
-- Horror threat is recomputed from the current scene after status duration processing.
function system.update(ctx, player)
    horror.update(ctx, player)
end

register.system({
    id = "status.horror",
    scope = "active",
    query = { component.PLAYER },
    after = { "status.duration" },
    before = { "status.regeneration" },
    update = system.update,
})

return system
