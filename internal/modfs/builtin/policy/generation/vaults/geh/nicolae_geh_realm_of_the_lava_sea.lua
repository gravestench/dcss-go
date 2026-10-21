-- The authored lava sea needs an endless-lava border around its encompass MAP.
local effects = require("constants.vault_effects")
local fill = require("constants.vault_border_fill")

local handler = {}

-- Record the source border choice for this vault's selected floor only.
function handler.border_fill(api)
    api:record(effects.BORDER_FILL, {
        style = fill.ENDLESS_LAVA,
    })
end

return handler
