-- The long market row repeats the short row's liquid ends across more shops.
-- Its own hook keeps that source choice local to this map.
local directives = require("constants.vault_directives")
local bazaar = require("constants.bazaar")

local handler = {}

-- Change only the end pools after the shared Bazaar palette has been drawn.
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
