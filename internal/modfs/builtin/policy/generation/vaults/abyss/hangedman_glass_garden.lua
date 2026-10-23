-- Theory of operation: hangedman_glass_garden keeps source geometry in DES.
-- Named hooks preserve the source declaration positions and use
-- the ordinary vault operation stream for deterministic choices.
local directives = require("constants.vault_directives")
local branches = require("ids.branches")

local handler = {}

-- Choose source alternatives from the placement context so a
-- dual-purpose map acts differently inside and outside Abyss.
local function conditional(api)
    if api:branch_id() == branches.BRANCH_ABYSS then
        api:emit(directives.TAGS, "no_exits")
        api:emit(directives.SHUFFLE, "345\", ABCD / ACBD / ADCB")
        api:emit(directives.SUBST, "+ = M, ' = x:5 c:2 v:1 b:1, \" = ., % = %%***|")
        api:emit(directives.SUBST, "AB : wwl, CD : wll")
        api:emit(directives.NSUBST, "M : 1:+ / 2 = mmm+ / * = m:19 +:1")
    else
        api:emit(directives.TAGS, "extra transparent")
        api:emit(directives.WEIGHT, "1")
        api:emit(directives.SUBST, "M = m, 34'\" = ., ABCD = W")
    end
end

handler.conditional = conditional

return handler
