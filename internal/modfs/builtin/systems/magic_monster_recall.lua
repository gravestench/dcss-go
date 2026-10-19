local component = require("constants.component")
local recall = require("policy.combat.monster_displacement.recall")

local system = {}

-- Theory of operation: Only the acting monster's saved recall timer ages.
-- It runs before AI chooses a fresh spell, so an interrupted chant cannot
-- survive invisibly or let the caster begin another recall too early.
function system.update(ctx, entity, delta)
    recall.tick(ctx, entity, delta)
end

register.system({
    id = "magic.monster_recall.tick",
    scope = "active",
    query = { component.MONSTER_RECALL },
    before = { "monster.decision" },
    update = system.update,
})

return system
