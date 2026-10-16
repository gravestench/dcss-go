local directives = require("constants.vault_directives")

local handler = {}

-- Port of arrival/small.des:2659-2663.
local function choose_fort_gate(api)
    if api:one_in(4) then
        api:emit(directives.SUBST, "\" : +, ' : . , - : ccc.")
    else
        api:emit(directives.SUBST, "\"'- : c")
    end
end

handler.choose_fort_gate = choose_fort_gate

return handler
