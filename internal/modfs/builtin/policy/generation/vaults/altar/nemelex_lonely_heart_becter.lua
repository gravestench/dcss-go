-- Theory of operation: Nemelex's lonely-heart scene is usually empty.
-- Its rare unique visitor is Jessica in Dungeon and Boris in Depths.
local branches = require("ids.branches")
local directives = require("constants.vault_directives")

local handler = {}

-- Keep the source four-to-one empty weighting for both branch versions.
local function choose_visitor(api)
    if api:branch_id() == branches.BRANCH_DEPTHS then
        api:emit(directives.MONS, "nothing w:4 / boris w:1")
    else
        api:emit(directives.MONS, "nothing w:4 / jessica w:1")
    end
end

handler.choose_visitor = choose_visitor

return handler
