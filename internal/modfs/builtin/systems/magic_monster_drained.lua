local component = require("constants.component")
local drain = require("policy.combat.monster_drain")

local system = {}

-- Theory of operation: The drain component is updated before AI evaluates the monster’s attack strength.
-- Drained monsters update their status after regeneration and before deciding an action.
function system.update(ctx, entity)
    drain.tick(ctx, entity)
end

register.system({
    id = "magic.monster_drained.tick",
    scope = "active",
    query = { component.MONSTER_DRAINED },
    after = { "monster.regeneration" },
    before = { "monster.decision" },
    update = system.update,
})

return system
