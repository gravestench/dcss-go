local component = require("constants.component")
local rage = require("policy.character.rage")

local system = {}

-- Theory of operation: The player guard prevents a monster action from aging the player rage timer.
-- Rage duration changes after combat, preserving its effect through the completed attack.
function system.update(ctx, entity, aut)
    if entity == ctx:player() then
        rage.tick(ctx, entity, aut)
    end
end

register.system({
    id = "character.rage",
    scope = "active",
    query = { component.PLAYER },
    after = { "attack.combat", "status.duration" },
    update = system.update,
})

return system
