-- This gate scales its raiding party with the scheduled Dungeon depth.
-- The map and shops stay in DES; only the source's monster choice is here.
local directives = require("constants.vault_directives")

local handler = {}

-- Deep entries can draw an orc knight, while earlier entries remain weaker.
local function choose_raiders(api)
    local monsters = api:absolute_depth() >= 10 and
        "weight:20 orc / orc warrior / weight:1 orc knight" or
        "weight:30 orc / orc warrior"

    api:emit(directives.MONS, monsters)
end

handler.choose_raiders = choose_raiders

return handler
