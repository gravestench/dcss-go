-- The lost city is an authored encompass map with open sea around its edge.
-- Geometry and the rune remain in DES; only border policy belongs here.
local effects = require("constants.vault_effects")
local fill = require("constants.vault_border_fill")

local handler = {}

-- Preserve the source border setting as typed level data for the renderer.
function handler.border_fill(api)
    api:record(effects.BORDER_FILL, {
        style = fill.OPEN_SEA,
    })
end

return handler
