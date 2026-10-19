-- Example: A good altar is emitted only outside the Dungeon branch where the base map already provides one.
local branches = require("ids.branches")
local directives = require("constants.vault_directives")

local handler = {}

-- A good altar is emitted only outside the Dungeon branch where the base map already provides one.
local function choose_good_altar(api)
    if api:branch_id() ~= branches.BRANCH_DUNGEON then
        api:emit(directives.KFEAT,
            "_ = altar_the_shining_one / altar_zin / altar_elyvilon")
    end
end

handler.choose_good_altar = choose_good_altar

return handler
