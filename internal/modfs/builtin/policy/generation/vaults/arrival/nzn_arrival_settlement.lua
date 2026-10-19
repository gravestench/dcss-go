-- Example: The two settlement layouts assign doors, water, altar, and wall glyphs in opposite patterns.
local directives = require("constants.vault_directives")

local handler = {}

-- The two settlement layouts assign doors, water, altar, and wall glyphs in opposite patterns.
local function choose_settlement_layout(api)
    if api:coinflip() then
        api:emit(directives.SUBST, "de = ', f = t, gh = ., ij = -, kpqr = x, s = @, uy = A")
    else
        api:emit(directives.SUBST, "dhjsy = x, gfru = -, ep = A, iq = ., k = @")
    end
end

handler.choose_settlement_layout = choose_settlement_layout

return handler
