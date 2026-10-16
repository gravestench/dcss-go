local directives = require("constants.vault_directives")

local handler = {}

-- Port of arrival/small.des:2687-2694.
local function choose_fort_gate(api)
    if api:one_in(4) then
        api:emit(directives.SUBST, "w : x, u : x, r : @")
    else
        api:emit(directives.SUBST, "r : x, u : @")
        api:emit(directives.NSUBST, "w = @ / w")
        api:emit(directives.NSUBST, "z = 1:@ / *:x")
        api:emit(directives.SUBST, "w : wwwwwwtt.")
    end
end

handler.choose_fort_gate = choose_fort_gate

return handler
