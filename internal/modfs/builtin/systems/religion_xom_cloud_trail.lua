-- The trail duration advances after the player's movement has used it.
-- The status is saved on the player; this system adds no hidden timer.
local component = require("constants.component")
local trail = require("policy.religion.xom.cloud_trail")

local system = {}

-- Monster actions do not consume the player's Xom trail duration.
function system.update(ctx, actor, elapsed_aut)
    if actor == ctx:player() then
        trail.tick(ctx, actor, elapsed_aut)
    end
end

register.system({
    id = "religion.xom_cloud_trail",
    scope = "active",
    query = { component.PLAYER },
    after = { "world.movement" },
    update = system.update,
})

return system
