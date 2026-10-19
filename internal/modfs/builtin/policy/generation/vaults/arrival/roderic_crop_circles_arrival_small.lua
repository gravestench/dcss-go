-- Example: The small crop circle independently rolls the same one-in-five glyph-2 palette.
local directives = require("constants.vault_directives")

local handler = {}

-- The small crop circle independently rolls the same one-in-five glyph-2 palette.
local function choose_crop_colour(api)
    if api:one_in(5) then
        api:emit(directives.SUBST, "1 = 2:100 1:20")
    else
        api:emit(directives.SUBST, "1 = 1:100 2:10")
    end
end

handler.choose_crop_colour = choose_crop_colour

return handler
