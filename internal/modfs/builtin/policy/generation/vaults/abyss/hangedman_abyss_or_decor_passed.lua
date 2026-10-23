-- Theory of operation: hangedman_abyss_or_decor_passed keeps source geometry in DES.
-- Named hooks preserve the source declaration positions and use
-- the ordinary vault operation stream for deterministic choices.
local directives = require("constants.vault_directives")
local branches = require("ids.branches")

local handler = {}

-- Choose source alternatives from the placement context so a
-- dual-purpose map acts differently inside and outside Abyss.
local function conditional(api)
    if api:branch_id() == branches.BRANCH_ABYSS then
        api:emit(directives.SUBST, "' = 00., \" = %%*..")
        api:emit(directives.SUBST, "x = xxxxcb, XY = ww...")
    else
        api:emit(directives.TAGS, "extra")
        api:emit(directives.SUBST, "x : xxxc, Y = x, X : x..")
        api:emit(directives.NSUBST, "; = 1:@ / *:., : = 1:@ / *:., ` = 1:@ / *:.")
    end
end

handler.conditional = conditional

return handler
