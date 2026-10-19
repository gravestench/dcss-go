-- Example: The rare blue-green palette also remaps c and x; the common palette keeps brown-grey tiles.
local directives = require("constants.vault_directives")

local handler = {}

-- The rare blue-green palette also remaps c and x; the common palette keeps brown-grey tiles.
local function choose_floor_palette(api)
    if api:one_in(4) then
        api:emit(directives.COLOUR, "' = blue")
        api:emit(directives.COLOUR, "\" = green")
        api:emit(directives.FTILE, "'{ = floor_pebble_blue")
        api:emit(directives.FTILE, "\" = floor_pebble_green")
        api:emit(directives.SUBST, "c = b, x = v")
    else
        api:emit(directives.COLOUR, "' = brown")
        api:emit(directives.COLOUR, "\" = lightgrey")
        api:emit(directives.FTILE, "'{ = floor_pebble_brown")
        -- yes, this variation uses American spelling for some reason
        api:emit(directives.FTILE, "\" = floor_pebble_lightgray")
    end
end

handler.choose_floor_palette = choose_floor_palette

return handler
