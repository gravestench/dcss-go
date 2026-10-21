-- Theory of operation: the DES file owns the lily's shape. Its named hook
-- changes only a reserved cell, showing how an independent mod adds Swamp
-- terrain without replacing a bundled vault or engine registration table.
local directives = require("constants.vault_directives")

local handler = {}

-- Convert the reserved center glyph before the source MAP is placed.
local function configure(api)
    api:emit(directives.SUBST, "s = w")
end

handler.configure = configure

return handler
