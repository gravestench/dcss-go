-- Theory of operation: deep levels allow the strongest hibernating occupant.
-- DES owns its room and monster slots; this hook only weights slot M.
local directives = require("constants.vault_directives")

local handler = {}

-- Match the source threshold, which uses absolute rather than local depth.
local function configure(api)
    if api:absolute_depth() > 14 then
        api:emit(directives.SUBST, "M = 1:1 2:9 3:20")
    else
        api:emit(directives.SUBST, "M = 2:1 3:4")
    end
end

handler.configure = configure

return handler
