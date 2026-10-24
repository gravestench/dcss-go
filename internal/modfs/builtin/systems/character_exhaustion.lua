-- Player exhaustion ages once per player action, after the action's effects
-- have been applied. Monster turns must not consume its timer.
local component = require("constants.component")
local exhaustion = require("policy.character.exhaustion")

local system = {}

-- The active system passes elapsed aut from the committed player action.
function system.update(ctx, player, elapsed_aut)
    if player == ctx:player() then
        exhaustion.tick(ctx, player, elapsed_aut)
    end
end

register.system({
    id = "character.exhaustion",
    scope = "active",
    query = { component.PLAYER_EXHAUSTION },
    after = { "attack.combat", "status.duration" },
    update = system.update,
})

return system
