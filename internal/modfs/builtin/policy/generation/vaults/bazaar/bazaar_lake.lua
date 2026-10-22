-- Blue lighting deepens the lake water around the five shops.
-- This hook runs after shared setup chooses one palette for the map.
local directives = require("constants.vault_directives")
local bazaar = require("constants.bazaar")

local handler = {}

-- Deepen the lake only for the blue palette; other palettes keep the source shallow water.
local function configure_colour(api)
    local colour = api:recall(bazaar.COLOUR_SETTING)

    if colour == bazaar.BLUE then
        api:emit(directives.SUBST, [=[w = W]=])
    end
end

handler.configure_colour = configure_colour

return handler
