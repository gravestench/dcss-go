-- Hellfire club opens its dollar terrain only while placed in Gehenna.
-- The source also allows this map on Zot floors, where it remains closed.
local branches = require("ids.branches")
local directives = require("constants.vault_directives")

local handler = {}

-- Preserve the source branch gate at the conditional substitution site.
function handler.configure(api)
    if api:branch_id() == branches.BRANCH_GEHENNA then
        api:emit(directives.SUBST, "d$ = .")
    end
end

return handler
