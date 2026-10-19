local senses = require("policy.character.senses")

local visibility = {}

-- Monster summon messages describe a cell in the world. A player who
-- cannot see that cell must not learn about an offscreen cast or expiry.
function visibility.player_sees(ctx, position)
    return senses.player_sees_cell(ctx, position)
end

return visibility
