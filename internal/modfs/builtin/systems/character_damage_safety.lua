local component = require("constants.component")
local safety = require("policy.character.damage_safety")

local system = {}

function system.update(ctx, player, aut)
    safety.tick(ctx, player, aut)
end

register.system({
    id = "status.damage_safety",
    scope = "active",
    query = { component.PLAYER, component.DAMAGE_SAFETY },
    after = { "status.duration" },
    before = { "status.regeneration" },
    update = system.update,
})

return system
