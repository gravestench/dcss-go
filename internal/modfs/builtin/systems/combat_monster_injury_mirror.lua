local component = require("constants.component")
local mirror = require("policy.combat.monster_support.injury_mirror")

local system = {}

-- Theory of operation: an acting monster ages its mirror aura while the
-- absolute recast clock remains on the ECS actor. No module global survives
-- a save, and the next AI decision sees the aged aura state.
function system.update(ctx, monster, elapsed_aut)
    mirror.tick(ctx, monster, elapsed_aut)
end

register.system({
    id = "combat.monster_injury_mirror.tick",
    scope = "active",
    query = { component.MONSTER_INJURY_MIRROR },
    before = { "monster.decision" },
    update = system.update,
})

return system
