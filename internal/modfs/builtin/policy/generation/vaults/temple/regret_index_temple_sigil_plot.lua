-- The sigil's source frame is endless lava, unlike the watery Temple maps.
-- Keep this environment choice attached to its own authored map.
local fill = require("constants.vault_border_fill")
local effects = require("constants.vault_effects")

local handler = {}

-- The border renderer uses this typed source intent after placing the MAP.
local function configure(api)
    api:record(effects.BORDER_FILL, {
        style = fill.ENDLESS_LAVA,
    })
end

handler.configure = configure

return handler
