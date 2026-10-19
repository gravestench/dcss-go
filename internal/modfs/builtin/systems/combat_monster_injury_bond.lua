-- Theory of operation: each protected monster ages its own saved bond
-- before deciding another action. Damage reads the same record immediately.
local component = require("constants.component")
local bond = require("policy.combat.monster_injury_bond")

local system = {}

-- Expired or orphaned bonds leave no protector handle in the ECS world.
function system.update(ctx, monster, elapsed_aut)
    bond.tick(ctx, monster, elapsed_aut)
end

register.system({
    id = "combat.monster_injury_bond.tick",
    scope = "active",
    query = { component.MONSTER_INJURY_BOND },
    before = { "monster.decision" },
    update = system.update,
})

return system
