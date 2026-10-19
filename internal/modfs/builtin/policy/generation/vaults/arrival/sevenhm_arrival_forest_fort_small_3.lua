-- Example: The third fort variant swaps an entrance marker and door against a sealed wall layout.
local directives = require("constants.vault_directives")

local handler = {}

-- The third fort variant swaps an entrance marker and door against a sealed wall layout.
local function choose_fort_gate(api)
    if api:one_in(4) then
        api:emit(directives.SUBST, "z : @ , Z : + , X = xx. , p : tR , m : c")
    else
        api:emit(directives.SUBST, "X : @, Z : c, z : x, p : x, m : .")
    end
end

handler.choose_fort_gate = choose_fort_gate

return handler
