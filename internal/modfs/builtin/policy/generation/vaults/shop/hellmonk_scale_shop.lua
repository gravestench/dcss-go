local branches = require("ids.branches")
local directives = require("constants.vault_directives")

local handler = {}

-- Port of builder/shops.des:1141-1148.
local function choose_scale_guard(api)
    local expression

    if api:branch_id() == branches.BRANCH_DEPTHS then
        expression = "D = golden dragon / iron dragon / quicksilver dragon / " ..
            "storm dragon / shadow dragon / pearl dragon w:1"
    elseif api:branch_id() == branches.BRANCH_DUNGEON and
        api:absolute_depth() < 13 then
        expression = "D = steam dragon / acid dragon"
    else
        expression = "D = fire dragon / ice dragon / swamp dragon"
    end

    api:emit(directives.KMONS, expression)
end

handler.choose_scale_guard = choose_scale_guard

return handler
