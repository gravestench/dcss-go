local branches = require("ids.branches")
local directives = require("constants.vault_directives")

local handler = {}

-- Port of builder/shops.des:628-630.
local function choose_good_altar(api)
    if api:branch_id() ~= branches.BRANCH_DUNGEON then
        api:emit(directives.KFEAT,
            "_ = altar_the_shining_one / altar_zin / altar_elyvilon")
    end
end

handler.choose_good_altar = choose_good_altar

return handler
