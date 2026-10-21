-- Theory of operation: this modded atoll keeps its cells in DES and changes
-- only the reserved shore glyph through a named hook in the same mod layer.
local directives = require("constants.vault_directives")

local handler = {}

-- Emit terrain at the hook's declaration point before the MAP is placed.
local function configure(api)
    api:emit(directives.SUBST, "s = w")
end

handler.configure = configure

return handler
