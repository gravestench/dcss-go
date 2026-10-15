local slow = require("policy.combat.monster_slow")

local system = {}

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
