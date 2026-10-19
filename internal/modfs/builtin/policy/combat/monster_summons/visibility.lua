local component = require("constants.component")

local visibility = {}

-- Monster summon messages describe a cell in the world. A player who
-- cannot see that cell must not learn about an offscreen cast or expiry.
function visibility.player_sees(ctx, position)
    local player = ctx:player()
    local origin = player and ctx:get(player, component.POSITION)

    return origin and position and
        origin.level_id == position.level_id and
        ctx:visible(position.level_id, origin.x, origin.y, 7,
            position.x, position.y) or false
end

return visibility
