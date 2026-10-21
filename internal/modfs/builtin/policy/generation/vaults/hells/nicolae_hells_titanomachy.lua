-- Theory of operation: the cracked giant battlefield is shared by all
-- four Hells. Its source L cells are lava in Dis and Gehenna, deep water
-- in Cocytus and Tartarus; all other substitutions stay in the DES map.
local branches = require("ids.branches")
local directives = require("constants.vault_directives")

local handler = {}

-- Choose the hazardous liquid from the current branch before the map's
-- giant and stair glyphs are resolved into typed level terrain.
local function configure(api)
    local branch_id = api:branch_id()

    if branch_id == branches.BRANCH_DIS or
        branch_id == branches.BRANCH_GEHENNA then
        api:emit(directives.SUBST, "L = l")
    elseif branch_id == branches.BRANCH_COCYTUS or
        branch_id == branches.BRANCH_TARTARUS then
        api:emit(directives.SUBST, "L = w")
    else
        error("Hell titanomachy needs a Hell subbranch")
    end
end

handler.configure = configure

return handler
