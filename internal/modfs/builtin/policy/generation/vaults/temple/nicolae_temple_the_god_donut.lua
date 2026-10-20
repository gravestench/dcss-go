-- The donut surrounds its altar ring with open sea in the source map.
-- Its interior shuffles stay in DES; only the border choice needs Lua.
local fill = require("constants.vault_border_fill")
local effects = require("constants.vault_effects")

local handler = {}

-- Record the source sea fill for the later whole-level placement pass.
local function configure(api)
    api:record(effects.BORDER_FILL, {
        style = fill.OPEN_SEA,
    })
end

handler.configure = configure

return handler
