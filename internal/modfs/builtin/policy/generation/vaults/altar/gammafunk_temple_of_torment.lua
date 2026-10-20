-- Theory of operation: the two-god torment temple has three source depth
-- tiers. Each tier changes both monster slots and keyed guard, while the
-- shallow tiers also thin glyph 2. The rest of its map and sarcophagus
-- naming remain in the .des file at their original positions.
local directives = require("constants.vault_directives")

local handler = {}

-- Emit one complete tier so array slots never mix monsters from two depths.
local function choose_torment(api)
    if api:depth() <= 4 then
        api:emit(directives.MONS, "zombie / skeleton")
        api:emit(directives.MONS,
            "mummy / shadow imp / wight / necrophage / phantom")
        api:emit(directives.KMONS,
            "3 = menkaure, necrophage / wight")
        api:emit(directives.SUBST, "2 = 2---")
    elseif api:depth() <= 7 then
        api:emit(directives.MONS,
            "zombie / skeleton / mummy / shadow imp / wight / " ..
            "necrophage / phantom")
        api:emit(directives.MONS, "wraith / vampire")
        api:emit(directives.KMONS,
            "3 = menkaure, wraith / vampire")
        api:emit(directives.SUBST, "2 = 12--")
    else
        api:emit(directives.MONS,
            "mummy / wight / zombie / skeleton / phantom")
        api:emit(directives.MONS,
            "wraith / vampire / shadow / w:5 death knight / " ..
            "w:5 skeletal warrior")
        api:emit(directives.MONS,
            "flayed ghost / death knight")
        api:emit(directives.NSUBST, "2 = 2 / 2-")
    end
end

handler.choose_torment = choose_torment

return handler
