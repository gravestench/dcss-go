-- The town's second monster slot changes its garrison theme once per
-- placement. DES keeps the walls and four shop sites in their source form.
local directives = require("constants.vault_directives")

local handler = {}

-- The source eight-way roll favors warriors, then priests, then wizards.
local function choose_garrison(api)
    local draw = api:roll(8)
    local monsters

    if draw > 5 then
        monsters = "orc wizard, orc sorcerer"
    elseif draw > 2 then
        monsters = "orc priest, orc high priest"
    else
        monsters = "orc warrior, orc knight"
    end

    api:emit(directives.MONS, monsters)
end

handler.choose_garrison = choose_garrison

return handler
