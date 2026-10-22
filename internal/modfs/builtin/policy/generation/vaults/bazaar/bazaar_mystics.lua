-- The mystics market uses its palette to decide which side pool is liquid.
-- Its shop assignments stay in the authored DES declarations.
local directives = require("constants.vault_directives")
local bazaar = require("constants.bazaar")

local handler = {}

-- Red and blue palettes exchange the two liquid glyphs around the magic shops.
local function configure_colour(api)
    local colour = api:recall(bazaar.COLOUR_SETTING)

    if colour == bazaar.RED then
        api:emit(directives.SUBST, [=[l = w]=])
    elseif colour == bazaar.BLUE then
        api:emit(directives.SUBST, [=[w = l]=])
    end
end

handler.configure_colour = configure_colour

return handler
