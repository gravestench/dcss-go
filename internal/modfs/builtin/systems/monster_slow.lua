local slow = require("policy.combat.monster_slow")

register.system({
    id = "monster.slow",
    scope = "active",
    query = {},
    after = { "monster.poison" },
    before = { "monster.decision" },
    update = function(ctx, entity)
        if ctx:has(entity, "core.ai") then
            slow.tick(ctx, entity)
        end
    end,
})
