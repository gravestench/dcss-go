-- Theory of operation: vine grip links are checked after melee and
-- movement, then invalid links are released before actor death cleanup.
local grip = require("policy.combat.monster_plants.vine_grip")

local system = {}

-- The vine's action ages its physical hold; any action can break a stale
-- relation after death, teleportation, or level movement.
function system.update(ctx, active, aut)
    grip.tick(ctx, active, aut)
end

register.system({
    id = "combat.monster_vine_grip",
    scope = "active",
    query = {},
    after = { "attack.combat" },
    before = { "actor.death" },
    update = system.update,
})

return system
