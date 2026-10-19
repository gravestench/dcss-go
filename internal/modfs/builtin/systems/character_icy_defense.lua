local icy_defense = require("policy.character.icy_defense")
local component = require("constants.component")

local system = {}

-- Theory of operation: The policy melts timed armour before regeneration reads the resulting defenses.
-- Icy defense depletes after general durations and before regeneration.
function system.update(ctx, actor, aut)
    icy_defense.tick(ctx, actor, aut)
end

register.system({
    id = "status.icy_defense",
    scope = "active",
    query = { component.PLAYER, component.ICY_DEFENSE },
    after = { "status.duration" },
    before = { "status.regeneration" },
    update = system.update,
})

return system
