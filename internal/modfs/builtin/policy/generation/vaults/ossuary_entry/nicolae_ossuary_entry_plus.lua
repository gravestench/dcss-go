-- The source plus entrance chooses one complete substitution theme.
-- Keep its substitutions together so the gate and surrounding walls
-- cannot be chosen by independent random draws.
local directives = require("constants.vault_directives")

local plus = {}

-- The winning branch emits source directives at this DES line's position.
local function choose_plus(api)
    if api:coinflip() then
        api:emit(directives.SUBST, "Dd = +, o = O, p = '")

        return
    end

    api:emit(directives.SUBST, "d = +, D = c, o = '")
    api:emit(directives.NSUBST, "p = O / '")
end

plus.choose_plus = choose_plus

return plus
