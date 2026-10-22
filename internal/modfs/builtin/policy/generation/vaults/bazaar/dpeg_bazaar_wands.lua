-- The wand market ties its two display pools to the selected Bazaar palette.
-- The hook follows shared setup and precedes the map cells.
local directives = require("constants.vault_directives")
local bazaar = require("constants.bazaar")

local handler = {}

-- Exchange liquid glyphs for red or blue while leaving the wand shop cells unchanged.
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
