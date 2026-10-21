-- The first ruined Orc gate adds a priestly guard after its undead MONS
-- slots. The deeper version can substitute a rare sorcerer.
local directives = require("constants.vault_directives")

local handler = {}

-- Preserve the source's weaker early gate and rare deep sorcerer draw.
local function choose_priest(api)
    local monsters = api:absolute_depth() >= 10 and
        "w:1 orc sorcerer / orc priest / nothing" or
        "orc priest / nothing"

    api:emit(directives.MONS, monsters)
end

handler.choose_priest = choose_priest

return handler
