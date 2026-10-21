-- Theory of operation: a rare source form keeps more of the fruit tree's
-- canopy. The common form clears perimeter glyphs and scatters fruit.
local directives = require("constants.vault_directives")

local handler = {}

-- Preserve both source branches and their directive order before MAP paint.
local function configure(api)
    if api:one_in(5) then
        api:emit(directives.SUBST, "'\"~ = . 1")
        api:emit(directives.SUBST, "0`-. = .:90 a:2 2:1")
        api:emit(directives.SUBST, "_ = .:90 a:4")
    else
        api:emit(directives.CLEAR, "'-_")
        api:emit(directives.SUBST, "`\" = . a 2:1")
        api:emit(directives.SUBST, "~. = .:90 a:2 2:1")
        api:emit(directives.SUBST, "0 = 1")
    end
end

handler.configure = configure

return handler
