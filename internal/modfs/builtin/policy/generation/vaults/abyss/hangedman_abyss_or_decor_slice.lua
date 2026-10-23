-- Theory of operation: hangedman_abyss_or_decor_slice keeps source geometry in DES.
-- Named hooks preserve the source declaration positions and use
-- the ordinary vault operation stream for deterministic choices.
local directives = require("constants.vault_directives")
local branches = require("ids.branches")

local handler = {}

-- Choose source alternatives from the placement context so a
-- dual-purpose map acts differently inside and outside Abyss.
local function conditional(api)
    if api:branch_id() == branches.BRANCH_ABYSS then
        api:emit(directives.SUBST, "' = 00., \" = %%., x = xxxxxcccb, cX = xxccb")
    else
        api:emit(directives.TAGS, "extra")
        api:emit(directives.SUBST, "x : xxxxc, c : xxc., X : xxc, '\" = .")
    end
end

handler.conditional = conditional

return handler
