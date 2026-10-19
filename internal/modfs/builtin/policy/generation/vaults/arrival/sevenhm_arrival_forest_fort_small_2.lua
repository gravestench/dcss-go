-- Example: This fort alternates the w and r entry markers, then chooses which water cells remain.
local directives = require("constants.vault_directives")

local handler = {}

-- This fort alternates the w and r entry markers, then chooses which water cells remain.
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
