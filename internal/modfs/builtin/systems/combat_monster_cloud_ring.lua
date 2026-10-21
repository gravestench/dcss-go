-- Theory of operation: source monster actions refresh cloud rings after
-- the actor has moved and attacked. A Pan lord reads its saved choice;
-- another species reads its catalog flag. Clouds remain saved world ECS
-- entities, rather than a second timer hidden on the monster.
local component = require("constants.component")
local ring = require("policy.combat.monster_cloud_ring")

local system = {}

-- Only the acting monster refreshes its field. Other actors may move
-- through existing clouds without triggering another ring pulse.
function system.update(ctx, actor)
    ring.surround(ctx, actor)
end

register.system({
    id = "combat.monster_cloud_ring",
    scope = "active",
    query = { component.AI },
    after = { "attack.combat" },
    before = { "actor.death" },
    update = system.update,
})

return system
