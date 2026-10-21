-- A same-path Lua layer can replace an existing Pan hook independently
-- of its source DES geometry. This fixture emits a visible no-op marker.
local directives = require("constants.vault_directives")

local handler = {}

-- Keep the source hook's roll while marking that the overlay was called.
local function choose_count(api)
    api:roll(15)
    api:emit(directives.SUBST, "a = a")
end

handler.choose_count = choose_count

return handler
