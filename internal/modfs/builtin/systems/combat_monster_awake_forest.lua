-- Theory of operation: a living monster's saved forest condition acts
-- before that monster chooses its next action. Querying only casters with
-- the component avoids scanning the whole level when no forest is awake.
local component = require("constants.component")
local forest = require("policy.combat.monster_plants.forest")

local system = {}

-- Spend the caster's elapsed action time on attacks and expiry.
function system.update(ctx, caster, aut)
    forest.tick(ctx, caster, aut)
end

register.system({
    id = "combat.monster_awake_forest",
    scope = "active",
    query = { component.MONSTER_AWAKE_FOREST },
    before = { "monster.decision" },
    update = system.update,
})

return system
