-- Theory of operation: Sif Muna's Orc or Dungeon room has two monster
-- slots. Before absolute depth six the second is an ordinary orc; deeper
-- floors use an orc warrior and a less restricted wizard choice.
local directives = require("constants.vault_directives")

local handler = {}

-- Emit both MONS slots together, avoiding the unselected source roster.
local function choose_orcs(api)
    if api:absolute_depth() < 6 then
        api:emit(directives.MONS, "orc wizard w:2 / nothing")
        api:emit(directives.MONS, "orc")
    else
        api:emit(directives.MONS, "orc wizard / nothing")
        api:emit(directives.MONS, "orc warrior")
    end
end

handler.choose_orcs = choose_orcs

return handler
