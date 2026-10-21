-- This iceberg uses the same source open-sea border as the ice city.
local effects = require("constants.vault_effects")
local fill = require("constants.vault_border_fill")

local handler = {}

-- Preserve the outer sea fill without executing the source Lua prelude.
local function border_fill(api)
    api:record(effects.BORDER_FILL, {
        style = fill.OPEN_SEA,
    })
end

handler.border_fill = border_fill

return handler
