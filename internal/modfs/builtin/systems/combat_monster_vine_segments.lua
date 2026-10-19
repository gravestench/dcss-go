-- Theory of operation: movement updates the head first, then this system
-- reconciles physical connector actors with the new shortest tree path.
-- It also removes connectors after a head's death or summon expiry.
local component = require("constants.component")
local chain = require("policy.combat.monster_plants.vine_chain")

local system = {}

-- A moved head can change the path without altering the saved anchor.
function system.update(ctx, active)
    if ctx:has(active, component.MONSTER_VINE) then
        chain.refresh(ctx, active)
    end

    chain.clean_orphans(ctx)
end

register.system({
    id = "combat.monster_vine_segments",
    scope = "active",
    query = {},
    after = { "world.movement", "magic.summon.expiry" },
    before = { "actor.death" },
    update = system.update,
})

return system
