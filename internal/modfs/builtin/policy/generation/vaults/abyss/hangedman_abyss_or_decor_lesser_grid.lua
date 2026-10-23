-- Theory of operation: hangedman_abyss_or_decor_lesser_grid keeps source geometry in DES.
-- Named hooks preserve the source declaration positions and use
-- the ordinary vault operation stream for deterministic choices.
local directives = require("constants.vault_directives")
local branches = require("ids.branches")

local handler = {}

-- Choose source alternatives from the placement context so a
-- dual-purpose map acts differently inside and outside Abyss.
local function conditional(api)
    if api:branch_id() == branches.BRANCH_ABYSS then
        api:emit(directives.SHUFFLE, "ABCDEF, \"'")
        api:emit(directives.SUBST, "A : cbx.., B : cbx., C : cbx.., D : cbx., E : cbx.., F : cbx.")
        api:emit(directives.SUBST, "\" = 0., ' = %*..., X = wl.")
    else
        api:emit(directives.TAGS, "extra")
        api:emit(directives.SUBST, "'\" = ., X : x.")
        api:emit(directives.SUBST, "A : xxc., B : xxc., C : xxc., D : xxc., E : xxc., F : xxc.")
    end
end

handler.conditional = conditional

return handler
