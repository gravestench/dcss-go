-- This gate rarely replaces its normal warrior with a knight on deep
-- Dungeon floors. The paired SUBST keeps the chosen guard and glyph aligned.
local directives = require("constants.vault_directives")

local handler = {}

-- Make the source one-in-ten knight decision only at absolute depth ten.
local function choose_guard(api)
    if api:absolute_depth() >= 10 and api:one_in(10) then
        api:emit(directives.MONS, "orc knight")
        api:emit(directives.SUBST, "G = .")
    else
        api:emit(directives.MONS, "orc warrior")
        api:emit(directives.SUBST, "G = 4")
    end
end

handler.choose_guard = choose_guard

return handler
