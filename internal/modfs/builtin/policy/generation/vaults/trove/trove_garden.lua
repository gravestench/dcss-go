-- The garden source chooses one of two vegetation layouts before its
-- later SUBST operations. One layout is sparse; the other scatters plants
-- by weighted substitutions. The authored MAP is unchanged.
local directives = require("constants.vault_directives")

local garden = {}

-- Emit the chosen branch in source order so subsequent DES substitutions
-- see the same glyph vocabulary as the original map script.
local function plants(api)
    if api:coinflip() then
        api:emit(directives.SUBST, '" = . 1:20')
        api:emit(directives.SUBST, "1 = . 1:1")
        api:emit(directives.SUBST, "' = .")
        return
    end

    api:emit(directives.SUBST, "1 = .")
    api:emit(directives.SUBST, "\" = '")
    api:emit(directives.SUBST, "w = w 1:2")
    api:emit(directives.NSUBST, ". = 12:M / 12:1 / *:.")
    api:emit(directives.SHUFFLE, "Mm")
    api:emit(directives.SUBST, "M = .")
    api:emit(directives.SUBST, ". = . 1:1")
    api:emit(directives.SUBST, "' = . 1:3")
end

garden.plants = plants

return garden
