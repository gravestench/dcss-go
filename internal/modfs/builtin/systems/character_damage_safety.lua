local component = require("constants.component")
local safety = require("policy.character.damage_safety")

local system = {}

-- Theory of operation: The policy ages the protection component before healing rules inspect the same actor.
-- Damage-safety timing is delegated to its policy between duration decay and regeneration.
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
