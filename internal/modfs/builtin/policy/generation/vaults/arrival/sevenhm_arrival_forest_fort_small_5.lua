-- Example: The fifth fort rolls a gate layout and a separate ruin pass over R and N markers.
local directives = require("constants.vault_directives")

local handler = {}

-- The fifth fort rolls a gate layout and a separate ruin pass over R and N markers.
local function choose_fort_gate(api)
    if api:one_in(4) then
        api:emit(directives.SUBST, "o = {")
        api:emit(directives.SUBST, "X : x, Y : @, p : ., Z: x")
    else
        api:emit(directives.NSUBST, "X = @ / @@xx., Z = @ / @@xx.")
        api:emit(directives.SUBST, "Y = x .:1 , o : . , p : [")
    end
end

-- The ruin pass runs after the gate choice, so its glyph edits see the selected gate.
local function choose_fort_ruins(api)
    if api:one_in(3) then
        api:emit(directives.NSUBST, "R = + / +c")
        api:emit(directives.NSUBST, "N = n / *=nnc")
        api:emit(directives.SUBST, "z : c")
    else
        api:emit(directives.SUBST, "R : c, z : +")
    end
end

handler.choose_fort_gate = choose_fort_gate
handler.choose_fort_ruins = choose_fort_ruins

return handler
