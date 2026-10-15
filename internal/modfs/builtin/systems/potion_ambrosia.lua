local component = require("constants.component")
local ambrosia = require("policy.potions.ambrosia")

local system = {}

function system.update(ctx, player, aut)
    if player == ctx:player() then
        ambrosia.tick(ctx, player, aut)
    end
end

register.system({
    id = "status.potion_ambrosia",
    scope = "active",
    query = { component.PLAYER },
    after = { "zap.player_confusion.tick" },
    before = { "status.regeneration" },
    update = system.update,
})

return system
