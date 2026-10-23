-- The ice-dragon entrance shares its MAP with watery branch variants.
-- Source substitutions open shallow or deep water at the chosen origin.
local branches = require("ids.branches")
local directives = require("constants.vault_directives")

local map = {}

-- Swamp turns x into trees; Shoals turns it into water. Other branches
-- retain the authored rock without an extra random decision.
function map.site_2(api)
    local branch = api:branch_id()

    if branch == branches.BRANCH_SWAMP then
        api:emit(directives.SUBST, "x = t")

    elseif branch == branches.BRANCH_SHOALS then
        api:emit(directives.SUBST, "x = w")
    end
end

return map
