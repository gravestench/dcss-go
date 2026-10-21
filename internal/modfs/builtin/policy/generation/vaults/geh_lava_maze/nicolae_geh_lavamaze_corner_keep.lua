-- Corner keep changes its gate and wall glyphs together so either layout
-- can host the source's possible paired stair positions.
local directives = require("constants.vault_directives")

local handler = {}

-- Preserve the source branch order before standard helper setup runs.
function handler.configure(api)
    if api:coinflip() then
        api:emit(directives.SUBST, "DH = c")
        api:emit(directives.NSUBST, "EFLM = c / +, JKNO = c / +")
    else
        api:emit(directives.SHUFFLE, "DKNO/FHML, EJ, NO")
        api:emit(directives.SUBST, "EFHN = c, DJKLMO = +")
    end
end

return handler
