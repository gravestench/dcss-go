-- Example: Only Dungeon branches collapse the stronger blood-shop guard marker 2 into marker 1.
local branches = require("ids.branches")
local directives = require("constants.vault_directives")

local handler = {}

-- Only Dungeon branches collapse the stronger blood-shop guard marker 2 into marker 1.
local function choose_blood_population(api)
    if api:branch_id() == branches.BRANCH_DUNGEON then
        api:emit(directives.SUBST, "2 = 1")
    end
end

handler.choose_blood_population = choose_blood_population

return handler
