-- Theory of operation: Xom's redecorated floor always has teleport traps
-- on caret cells. The separate tilde cells may be shafts only before the
-- last floor of their current branch.
local directives = require("constants.vault_directives")

local handler = {}

-- Choose the source tilde trap menu from the local branch bottom.
local function choose_traps(api)
    if api:depth() == api:branch_bottom() then
        api:emit(directives.KFEAT,
            "~ = teleport trap / alarm trap / dispersal trap")
    else
        api:emit(directives.KFEAT,
            "~ = shaft trap / teleport trap / alarm trap / dispersal trap")
    end
end

handler.choose_traps = choose_traps

return handler
