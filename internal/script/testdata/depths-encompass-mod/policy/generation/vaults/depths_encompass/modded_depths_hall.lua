-- A sparse mod can add behavior beside its new DES map without editing Go.
local directives = require("constants.vault_directives")

local handler = {}

-- Emit a visible source substitution at the map's hook position. The
-- placement test checks the effective layered resolver, not a copied parser.
local function configure(api)
    api:emit(directives.SUBST, ". = .")
end

handler.configure = configure

return handler
