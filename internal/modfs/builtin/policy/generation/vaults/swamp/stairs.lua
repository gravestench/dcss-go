-- Theory of operation: two concentric Swamp maps share the same source
-- depth rule. The first floor has no upward branch exit in their center;
-- the last floor must not lead deeper. DES retains the ring geometry.
local directives = require("constants.vault_directives")

local handler = {}

-- Emit only the branch-depth variant that source DES Lua would have read.
local function configure(api)
    if api:depth() == 1 then
        api:emit(directives.SUBST,
            "P = p, Q = q, R = r, S = s, Z = z")
    elseif api:depth_fraction() < 1 then
        api:emit(directives.SHUFFLE, "PQRSZ/pqrsz")
    end
end

handler.configure = configure

return handler
