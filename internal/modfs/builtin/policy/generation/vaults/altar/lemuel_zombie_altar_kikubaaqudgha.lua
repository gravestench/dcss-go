-- Theory of operation: the same Kiku altar can show minor animal undead in
-- Dungeon or a depth-scaled generic zombie in Depths. Both source choices
-- keep the large nothing weight, leaving most map cells empty.
local branches = require("ids.branches")
local directives = require("constants.vault_directives")

local handler = {}

-- Emit only the branch's source MONS choice, preserving its weighted vacancy.
local function choose_undead(api)
    if api:branch_id() == branches.BRANCH_DEPTHS then
        api:emit(directives.MONS, "zombie w:20 / nothing w:90")
    else
        api:emit(directives.MONS,
            "rat zombie / bat zombie / nothing w:90")
    end
end

handler.choose_undead = choose_undead

return handler
