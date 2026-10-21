-- This ice city fills its authored outer border with open sea.
local effects = require("constants.vault_effects")
local fill = require("constants.vault_border_fill")

local handler = {}

-- Keep the source border request as a saved typed level effect.
local function border_fill(api)
    api:record(effects.BORDER_FILL, {
        style = fill.OPEN_SEA,
    })
end

handler.border_fill = border_fill

return handler
