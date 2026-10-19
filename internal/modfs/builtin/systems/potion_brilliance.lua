local component = require("constants.component")
local brilliance = require("policy.potions.brilliance")

local system = {}

-- Theory of operation: The brilliance timer is spent before regeneration observes spell status.
-- Brilliance's remaining duration is aged between status decay and regeneration.
function system.update(ctx, player, aut)
    if player == ctx:player() then
        brilliance.tick(ctx, player, aut)
    end
end

register.system({
    id = "status.potion_brilliance",
    scope = "active",
    query = { component.PLAYER },
    after = { "status.duration" },
    before = { "status.regeneration" },
    update = system.update,
})

return system
