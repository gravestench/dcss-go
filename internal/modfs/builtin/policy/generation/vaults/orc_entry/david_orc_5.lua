-- The two variable MONS slots of this Beogh gate are separate source sites.
-- Keeping them separate preserves the fixed priest between the two draws.
local directives = require("constants.vault_directives")

local handler = {}

-- The outer raiders gain warriors and a rare knight at greater depth.
local function choose_raiders(api)
    local depth = api:absolute_depth()
    local monsters

    if depth >= 10 then
        monsters = "orc w:32 / w:7 orc warrior / w:1 orc knight"
    elseif depth >= 8 then
        monsters = "orc w:40 / orc warrior"
    else
        monsters = "orc w:80 / orc warrior"
    end

    api:emit(directives.MONS, monsters)
end

-- The second variable group follows the fixed priest's source position.
local function choose_escort(api)
    local monsters = api:absolute_depth() >= 10 and
        "orc w:32 / w:7 orc warrior / w:1 orc knight" or
        "orc w:32 / w:7 orc warrior"

    api:emit(directives.MONS, monsters)
end

handler.choose_raiders = choose_raiders
handler.choose_escort = choose_escort

return handler
