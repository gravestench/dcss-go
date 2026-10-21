-- The companion DES file owns this alcove's shape. Its named hook replaces
-- the reserved glyph before placement, without registering a Go handler.
local directives = require("constants.vault_directives")

local handler = {}

-- Turn the marker into a floor so a new Pan primary has an open center.
local function configure(api)
    api:emit(directives.SUBST, "a = .")
end

handler.configure = configure

return handler
