-- Source overflow maps become ordinary extra vaults after D:10 or outside
-- Dungeon. The same check appeared in most source declarations; one shared
-- named hook keeps its rule in one place while each DES file stays readable.
local branches = require("ids.branches")
local directives = require("constants.vault_directives")

local interest = {}

-- Emit the source extra tag only for the branch and depth where the map may
-- appear as decoration rather than consuming a scheduled overflow god.
function interest.apply(api)
    if api:branch_id() ~= branches.BRANCH_DUNGEON or
        api:depth() > 10 then
        api:emit(directives.TAGS, "extra")
    end
end

return interest
