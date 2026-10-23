-- Swamp, Shoals, and Spider replace the same ice-statue approach terrain
-- differently. The branch at placement, not a global cave flag, decides.
local branches = require("ids.branches")
local directives = require("constants.vault_directives")

local map = {}

-- Apply the source terrain alternatives after the fixed web-trap KFEAT.
function map.site_2(api)
    local branch = api:branch_id()

    if branch == branches.BRANCH_SWAMP then
        api:emit(directives.SUBST, "+ = ., x = t")

    elseif branch == branches.BRANCH_SHOALS then
        api:emit(directives.SUBST, "x = w")

    elseif branch == branches.BRANCH_SPIDER then
        api:emit(directives.SUBST, "+ = ^")
    end
end

return map
