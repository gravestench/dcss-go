local component = require("constants.component")
local resistance = require("policy.potions.resistance")

local system = {}

function system.update(ctx, player, aut)
    if player == ctx:player() then
        resistance.tick(ctx, player, aut)
    end
end

register.system({
    id = "status.potion_resistance",
    scope = "active",
    query = { component.PLAYER },
    after = { "status.duration" },
    before = { "status.regeneration" },
    update = system.update,
})

return system
