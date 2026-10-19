-- Example: The spoke gate opens only on one coinflip outcome by remapping q, r, and p.
local directives = require("constants.vault_directives")

local handler = {}

-- The spoke gate opens only on one coinflip outcome by remapping q, r, and p.
local function choose_spoke_gate(api)
    if api:coinflip() then
        api:emit(directives.SUBST, "q : @, r : x, p : .")
    end
end

handler.choose_spoke_gate = choose_spoke_gate

return handler
