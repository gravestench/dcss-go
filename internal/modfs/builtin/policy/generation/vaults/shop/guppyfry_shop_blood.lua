local branches = require("ids.branches")
local directives = require("constants.vault_directives")

local handler = {}

-- Port of builder/shops.des:573-575.
local function choose_blood_population(api)
    if api:branch_id() == branches.BRANCH_DUNGEON then
        api:emit(directives.SUBST, "2 = 1")
    end
end

handler.choose_blood_population = choose_blood_population

return handler
