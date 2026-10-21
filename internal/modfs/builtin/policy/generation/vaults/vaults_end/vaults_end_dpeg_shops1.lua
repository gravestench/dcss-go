-- Theory of operation: this mall quadrant has two source doorway patterns.
-- The rare pattern opens A and erases C/D; the common one shuffles C/D
-- before keeping C open. The decision stays at its authored DES position.
local directives = require("constants.vault_directives")

local handler = {}

-- Preserve source operation order so later substitutions see the right glyphs.
local function choose_shop_pattern(api)
    if api:one_in(4) then
        api:emit(directives.SUBST, "A = +, a = ., CD = x")
    else
        api:emit(directives.SHUFFLE, "CD")
        api:emit(directives.SUBST, "C = ., DAa = x")
    end
end

handler.choose_shop_pattern = choose_shop_pattern

return handler
