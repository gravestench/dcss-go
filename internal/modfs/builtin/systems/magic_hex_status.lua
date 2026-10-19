local component = require("constants.component")
local status = require("policy.combat.monster_hexes.status")

local system = {}

-- Theory of operation: Hex timers are reduced before AI tests whether a monster can act.
-- Monster hex durations advance before the next AI choice.
function system.update(ctx, actor, aut)
    status.tick(ctx, actor, aut)
end

register.system({
    id = "magic.hex_status.tick",
    scope = "active",
    query = {
        component.HEX_STATUS,
    },
    after = {
        "status.duration",
    },
    update = system.update,
})

return system
