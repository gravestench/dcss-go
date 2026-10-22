-- The short market row has two ornamental liquid ends.
-- Shared setup picks one palette before this map chooses their material.
local directives = require("constants.vault_directives")
local bazaar = require("constants.bazaar")

local handler = {}

-- Red and blue palettes swap the two liquid glyphs so the row stays visually coherent.
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
