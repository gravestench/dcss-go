local component = require("constants.component")
local invisibility = require("policy.potions.invisibility")

local system = {}

-- Theory of operation: Invisibility can expire before the next regeneration and perception pass.
-- Invisibility's remaining duration is aged before regeneration.
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
