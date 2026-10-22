-- The ribbon market threads shops between two liquid banks.
-- Its bank substitution follows the shared tileset draw.
local directives = require("constants.vault_directives")
local bazaar = require("constants.bazaar")

local handler = {}

-- Match the ribbon banks to red or blue without rerolling the palette.
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
