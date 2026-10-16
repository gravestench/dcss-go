local directives = require("constants.vault_directives")

local handler = {}

-- Port of arrival/small.des:2713-2717.
local function choose_fort_gate(api)
    if api:one_in(4) then
        api:emit(directives.SUBST, "z : @ , Z : + , X = xx. , p : tR , m : c")
    else
        api:emit(directives.SUBST, "X : @, Z : c, z : x, p : x, m : .")
    end
end

handler.choose_fort_gate = choose_fort_gate

return handler
