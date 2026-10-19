local slow = require("policy.combat.monster_slow")

local system = {}

-- Theory of operation: Slow timers are aged after poison and before AI decides how to act.
-- Slow duration is updated after poison and before AI chooses an action.
function system.update(ctx, entity)
    if ctx:has(entity, "core.ai") then
        slow.tick(ctx, entity)
    end
end

register.system({
    id = "monster.slow",
    scope = "active",
    query = {},
    after = { "monster.poison" },
    before = { "monster.decision" },
    update = system.update,
})

return system
