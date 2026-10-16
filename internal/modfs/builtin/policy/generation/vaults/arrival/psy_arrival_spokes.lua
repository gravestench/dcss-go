local directives = require("constants.vault_directives")

local handler = {}

-- Port of arrival/small.des:3154-3156.
local function choose_spoke_gate(api)
    if api:coinflip() then
        api:emit(directives.SUBST, "q : @, r : x, p : .")
    end
end

handler.choose_spoke_gate = choose_spoke_gate

return handler
