-- Example: Two thirds of ford layouts replace the crossing markers with randomized shallow terrain.
local directives = require("constants.vault_directives")

local handler = {}

-- Two thirds of ford layouts replace the crossing markers with randomized shallow terrain.
local function choose_ford(api)
    if api:roll(3) > 0 then
        api:emit(directives.SUBST, "T=x, \"=., '=.")
    else
        api:emit(directives.SUBST, "\"=T.., '=T...., T:Tttt, T=t x:1")
    end
end

handler.choose_ford = choose_ford

return handler
