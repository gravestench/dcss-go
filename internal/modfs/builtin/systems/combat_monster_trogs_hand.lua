local component = require("constants.component")
local hand = require("policy.combat.monster_support.trogs_hand")

local system = {}

-- Theory of operation: an acting monster spends protection time before its
-- regeneration and spell resistance can use the status on this action.
-- The remaining aut is saved on the monster and survives level travel.
function system.update(ctx, monster, elapsed_aut)
    hand.tick(ctx, monster, elapsed_aut)
end

register.system({
    id = "combat.monster_trogs_hand.tick",
    scope = "active",
    query = { component.MONSTER_TROGS_HAND },
    before = { "monster.regeneration" },
    update = system.update,
})

return system
