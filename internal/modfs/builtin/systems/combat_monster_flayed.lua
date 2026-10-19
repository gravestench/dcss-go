-- Theory of operation: a flayed actor ages its own saved timer after each
-- action. A hostile ghost in sight suspends decay; ghost death removes the
-- condition through the separate death owner before ECS deletion.
local component = require("constants.component")
local flay = require("policy.combat.monster_flay")

local system = {}

-- The owner restores only actual damage when the temporary wound expires.
function system.update(ctx, victim, elapsed_aut)
    flay.tick(ctx, victim, elapsed_aut)
end

register.system({
    id = "combat.monster_flayed.tick",
    scope = "active",
    query = { component.MONSTER_FLAYED },
    before = { "monster.decision" },
    update = system.update,
})

return system
