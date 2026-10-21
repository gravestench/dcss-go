-- The storm palace uses a full DES MAP and tagged center/corner helpers.
-- This hook carries the source open-sea border choice without duplicating
-- the authored structure in Lua.
local effects = require("constants.vault_effects")
local fill = require("constants.vault_border_fill")

local handler = {}

-- Surround the palace with sea after its DES cells are projected.
function handler.border_fill(api)
    api:record(effects.BORDER_FILL, {
        style = fill.OPEN_SEA,
    })
end

return handler
