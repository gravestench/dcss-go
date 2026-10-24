-- Source xom_tick runs after every completed player action. The system
-- only connects that timing to the Lua owner; it keeps no extra state.
local component = require("constants.component")
local actions = require("policy.religion.xom.actions")

local system = {}

-- Monster turns and zero-time probes cannot spend Xom's interest or RNG.
function system.update(ctx, actor, elapsed_aut)
    if actor == ctx:player() and elapsed_aut > 0 then
        actions.tick(ctx, actor)
    end
end

register.system({
    id = "religion.xom.reaction",
    scope = "active",
    query = { component.PLAYER },
    after = {
        "actor.death",
        "religion.upkeep",
    },
    update = system.update,
})

return system
