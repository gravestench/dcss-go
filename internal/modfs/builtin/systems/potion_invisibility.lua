local component = require("constants.component")
local invisibility = require("policy.potions.invisibility")

local system = {}

function system.update(ctx, player, aut)
    if player == ctx:player() then
        invisibility.tick(ctx, player, aut)
    end
end

register.system({
    id = "status.potion_invisibility",
    scope = "active",
    query = { component.PLAYER },
    after = { "status.duration" },
    before = { "status.regeneration" },
    update = system.update,
})

return system
