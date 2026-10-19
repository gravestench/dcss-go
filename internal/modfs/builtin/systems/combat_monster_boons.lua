local boons = require("policy.combat.monster_support.boons")
local component = require("constants.component")

local system = {}

-- Theory of operation: every acting monster ages its own saved boon timers
-- before choosing a new intent. Other actors' actions leave these timers
-- intact; the engine's action duration, not file load order, drives expiry.
function system.update(ctx, monster, elapsed_aut)
    boons.tick(ctx, monster, elapsed_aut)
end

register.system({
    id = "combat.monster_boons.tick",
    scope = "active",
    query = { component.MONSTER_BOONS },
    before = { "monster.decision" },
    update = system.update,
})

return system
