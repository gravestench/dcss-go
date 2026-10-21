-- The central iron tower closes its braces differently by Dis depth.
local directives = require("constants.vault_directives")

local handler = {}

-- The first floor closes every brace; later ordinary floors mix exits.
function handler.configure(api)
    if api:depth() == 1 then
        api:emit(directives.SUBST, "{ = }")
    elseif api:depth_fraction() < 1 then
        api:emit(directives.SUBST, "{ = {}")
    end
end

return handler
