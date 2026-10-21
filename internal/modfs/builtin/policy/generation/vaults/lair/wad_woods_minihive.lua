-- Theory of operation: the bee guard is softened on early Dungeon and Lair
-- floors, while the same authored hive and other keyed actors remain intact.
local branches = require("ids.branches")
local directives = require("constants.vault_directives")

local handler = {}

-- Replace source slot eight before keyed monster resolution on early floors.
local function configure(api)
    local branch = api:branch_id()
    local depth = api:depth()

    if branch == branches.BRANCH_LAIR and depth < 4 or
        branch == branches.BRANCH_DUNGEON and depth < 12 then
        api:emit(directives.SUBST, "8 = 6")
    end
end

handler.configure = configure

return handler
