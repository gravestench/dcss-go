-- Example: The first fort variant rarely opens its quoted gate and replaces the nearby fence glyphs.
local directives = require("constants.vault_directives")

local handler = {}

-- The first fort variant rarely opens its quoted gate and replaces the nearby fence glyphs.
local function choose_fort_gate(api)
    if api:one_in(4) then
        api:emit(directives.SUBST, "\" : +, ' : . , - : ccc.")
    else
        api:emit(directives.SUBST, "\"'- : c")
    end
end

handler.choose_fort_gate = choose_fort_gate

return handler
