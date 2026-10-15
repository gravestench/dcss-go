local component = require("constants.component")
local drain = require("policy.combat.monster_drain")

local system = {}

function system.update(ctx, entity)
    drain.tick(ctx, entity)
end

register.system({
    id = "magic.monster_drained.tick",
    scope = "active",
    query = { component.MONSTER_DRAINED },
    after = { "monster.regeneration" },
    before = { "monster.decision" },
    update = system.update,
})

return system
