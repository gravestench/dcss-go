-- Source Zot overgrown stairs are a live world event, not a generation
-- script. The saved ECS controller owns its next deadline and plant count.
local overgrown = require("policy.world.zot_overgrown")

local system = {}

-- The policy checks player identity because active systems also visit
-- monsters; one monster action must not advance this player LOS trigger.
function system.update(ctx, actor)
    overgrown.update(ctx, actor)
end

register.system({
    id = "world.zot_overgrown",
    scope = "active",
    query = {},
    after = { "world.movement" },
    update = system.update,
})

return system
