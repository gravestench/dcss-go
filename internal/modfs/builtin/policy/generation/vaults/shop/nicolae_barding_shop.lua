local branches = require("ids.branches")
local directives = require("constants.vault_directives")

local handler = {}

-- Port of builder/shops.des:649-653.
local function choose_barding_guard(api)
    if api:branch_id() == branches.BRANCH_SNAKE then
        api:emit(directives.KMONS, "s = naga w:50 / naga warrior")
    else
        api:emit(directives.KMONS, "s = centaur w:50 / centaur warrior")
    end
end

handler.choose_barding_guard = choose_barding_guard

return handler
