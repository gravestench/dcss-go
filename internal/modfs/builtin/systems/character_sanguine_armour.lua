local component = require("constants.component")
local sanguine = require("policy.character.sanguine_armour")

local system = {}

function system.update(ctx, actor, aut)
    sanguine.tick(ctx, actor, aut)
end

register.system({
    id = "status.sanguine_armour",
    scope = "active",
    query = { component.PLAYER, component.SANGUINE_ARMOUR },
    after = { "status.poison" },
    update = system.update,
})

return system
