local poison = require("policy.combat.monster_poison")

register.system({
    id = "monster.poison",
    scope = "active",
    query = {},
    after = { "monster.regeneration" },
    before = { "monster.decision" },
    update = function(ctx, entity)
        if ctx:has(entity, "core.ai") then
            poison.tick(ctx, entity)
        end
    end,
})
