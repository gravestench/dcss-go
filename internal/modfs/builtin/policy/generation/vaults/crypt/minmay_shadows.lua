-- Theory of operation: this map keeps source geometry in its DES file.
-- The methods below run at authored source positions, so emitted
-- directives see earlier map substitutions and retain seeded order.
local directives = require("constants.vault_directives")
local branches = require("ids.branches")

local handler = {}

-- Tar and Crypt use different source substitutions for this shared map.
-- Source operation:
-- : if you.in_branch("Tar") then
-- NSUBST:  d = 1:} / 1:.
-- : else
-- SUBST:   x = c, 3 = .
-- : end
local function choose_branch_terrain(api)
    if api:branch_id() == branches.BRANCH_TARTARUS then
        api:emit(directives.NSUBST, "d = 1:} / 1:.")
    else
        api:emit(directives.SUBST, "x = c, 3 = .")
    end
end

handler.choose_branch_terrain = choose_branch_terrain

return handler
