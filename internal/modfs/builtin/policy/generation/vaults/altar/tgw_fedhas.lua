-- Theory of operation: shallow Fedhas maps keep their bushes and oklob
-- enclosure closed. After absolute depth five, the source shuffles PQR
-- and opens two extra routes before its unconditional P substitution.
local directives = require("constants.vault_directives")

local handler = {}

-- Insert the deeper enclosure edits at the source conditional position.
local function open_deep_enclosure(api)
    if api:absolute_depth() <= 5 then
        return
    end

    api:emit(directives.SHUFFLE, "PQR")
    api:emit(directives.SUBST, "Q = 114, R = 11124")
end

handler.open_deep_enclosure = open_deep_enclosure

return handler
