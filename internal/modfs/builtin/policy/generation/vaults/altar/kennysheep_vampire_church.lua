-- Theory of operation: the same church geometry belongs to early Dungeon
-- or Depths. Its monster arrays change together so source numeric glyphs
-- still draw from the appropriate local population after placement.
local branches = require("ids.branches")
local directives = require("constants.vault_directives")

local handler = {}

-- Emit both source MONS slots in their original order for each branch.
local function choose_vampires(api)
    if api:branch_id() == branches.BRANCH_DEPTHS then
        api:emit(directives.MONS, "vampire knight / nothing")
        api:emit(directives.MONS, "vampire mage")
    else
        api:emit(directives.MONS, "vampire bat / nothing w:7")
        api:emit(directives.MONS, "bat skeleton / bat zombie")
    end
end

handler.choose_vampires = choose_vampires

return handler
