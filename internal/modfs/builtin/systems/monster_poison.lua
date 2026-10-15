local poison = require("policy.combat.monster_poison")

local system = {}

function system.update(ctx, entity)
    if ctx:has(entity, "core.ai") then
        poison.tick(ctx, entity)
    end
end

register.system({
    id = "monster.poison",
    scope = "active",
    query = {},
    after = { "monster.regeneration" },
    before = { "monster.decision" },
    update = system.update,
})

return system
