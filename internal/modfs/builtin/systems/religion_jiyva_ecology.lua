-- One player-time system advances Jiyva's saved random timer. It runs on
-- every timed action, including actions during which the player is not a
-- worshipper, because the source timer itself exists independently.
local component = require("constants.component")
local periodic = require("policy.religion.jiyva.periodic")

local system = {}

-- The scheduler supplies the action's elapsed aut; a monster action must
-- not advance the player's periodic god timer a second time.
function system.update(ctx, actor, elapsed_aut)
    if actor ~= ctx:player() then
        return
    end

    periodic.tick(ctx, actor, elapsed_aut)
end

register.system({
    id = "religion.jiyva.ecology",
    scope = "active",
    query = {},
    after = { "world.stairs", "item.pickup" },
    update = system.update,
})

return system
