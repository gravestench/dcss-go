local enchant = require("policy.combat.monster_enchant")

local system = {}

function system.update(ctx, entity)
    if ctx:has(entity, "core.ai") then
        enchant.tick(ctx, entity)
    end
end

register.system({
    id = "monster.enchant",
    scope = "active",
    query = {},
    after = { "monster.slow" },
    before = { "monster.decision" },
    update = system.update,
})

return system
