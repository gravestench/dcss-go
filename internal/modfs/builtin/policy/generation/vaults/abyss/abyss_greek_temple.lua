-- Theory of operation: abyss_greek_temple keeps source geometry in DES.
-- Named hooks preserve the source declaration positions and use
-- the ordinary vault operation stream for deterministic choices.
local directives = require("constants.vault_directives")

local handler = {}

-- Choose source alternatives from the placement context so a
-- dual-purpose map acts differently inside and outside Abyss.
local function conditional(api)
    if api:setting("wu_jian_available") == false then
        api:emit(directives.SHUFFLE, "ABCDEFHIJKLMNOPQRSTU")
        api:emit(directives.SUBST, "V = .")
    else
        api:emit(directives.SHUFFLE, "ABCDEFHIJKLMNOPQRSTUV")
    end
end

handler.conditional = conditional

return handler
