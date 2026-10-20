-- Theory of operation: the three good gods share one altar layout, but
-- each placement chooses either a silver marble or golden limestone theme.
-- The one-in-two draw changes only the keyed wall and visual directives;
-- altar positions and source statue geometry remain in the .des file.
local directives = require("constants.vault_directives")

local handler = {}

-- Emit one complete source palette at the old conditional position.
local function choose_theme(api)
    if api:one_in(2) then
        api:emit(directives.KFEAT, "c = v")
        api:emit(directives.TILE, "c = dngn_metal_wall_white")
        api:emit(directives.COLOUR, "c- = white")
        api:emit(directives.FTILE, "-aDEFG = floor_w_marble")
    else
        api:emit(directives.TILE, "c = wall_church")
        api:emit(directives.COLOUR, "c- = yellow")
        api:emit(directives.FTILE, "-aDEFG = floor_limestone")
    end
end

handler.choose_theme = choose_theme

return handler
