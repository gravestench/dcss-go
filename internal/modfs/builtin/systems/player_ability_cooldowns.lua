local component = require("constants.component")
local cooldowns = require("policy.abilities.cooldowns")

local system = {}

-- Theory of operation: Cooldown components are aged before regeneration and the next ability menu.
-- Ability cooldowns decrease after general durations and before regeneration.
function system.update(ctx, player, aut)
    if player == ctx:player() then
        cooldowns.tick(ctx, player, aut)
    end
end

register.system({
    id = "status.ability_cooldowns",
    scope = "active",
    query = { component.PLAYER },
    after = { "status.duration" },
    before = { "status.regeneration" },
    update = system.update,
})

return system
