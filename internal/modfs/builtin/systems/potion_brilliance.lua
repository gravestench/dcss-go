local component = require("constants.component")
local brilliance = require("policy.potions.brilliance")

local system = {}

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
