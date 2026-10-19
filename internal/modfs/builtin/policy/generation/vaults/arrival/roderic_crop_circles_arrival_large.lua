-- Example: The large crop circle has a one-in-five chance to favor glyph 2 over glyph 1.
local directives = require("constants.vault_directives")

local handler = {}

-- The large crop circle has a one-in-five chance to favor glyph 2 over glyph 1.
local function choose_crop_colour(api)
    if api:one_in(5) then
        api:emit(directives.SUBST, "1 = 2:100 1:20")
    else
        api:emit(directives.SUBST, "1 = 1:100 2:10")
    end
end

handler.choose_crop_colour = choose_crop_colour

return handler
