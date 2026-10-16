local directives = require("constants.vault_directives")

local handler = {}

-- Port of arrival/small.des:235-247.
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
