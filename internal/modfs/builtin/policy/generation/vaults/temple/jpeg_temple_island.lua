-- The island's authored terrain has an open sea beyond the visible map.
-- The border choice belongs to this Temple map, not the branch generally.
local fill = require("constants.vault_border_fill")
local effects = require("constants.vault_effects")

local handler = {}

-- Preserve the source border choice as typed generation data so the final
-- Temple grid can surround the authored island without a Go map-ID case.
local function configure(api)
    api:record(effects.BORDER_FILL, {
        style = fill.OPEN_SEA,
    })
end

handler.configure = configure

return handler
