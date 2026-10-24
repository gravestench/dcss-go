-- A level-one character has no experience level available to sacrifice.
local component = require("constants.component")

local rule = {}

-- The source checks the player's current level against one sacrificed level.
function rule.eligible(ctx, player)
    local progress = ctx:get(player, component.PROGRESSION)

    return progress and progress.level > 1 or false
end

return rule
