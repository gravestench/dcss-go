-- Theory of operation: source monster actions refresh cloud rings after
-- the actor has moved and attacked. The saved lord component identifies the
-- ring; the shared cloud placement owner stores each resulting field.
local component = require("constants.component")
local ring = require("policy.combat.monster_cloud_ring")

local system = {}

-- Only the acting lord refreshes its field. Other monsters and the player
-- may move through existing clouds without triggering another ring pulse.
function system.update(ctx, actor)
    ring.surround(ctx, actor)
end

register.system({
    id = "combat.pan_lord_cloud_ring",
    scope = "active",
    query = { component.PANDEMONIUM_LORD },
    after = { "attack.combat" },
    before = { "actor.death" },
    update = system.update,
})

return system
