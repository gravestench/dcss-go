-- The second ruined Orc gate has a different early priest pool, so its
-- handler stays beside its own DES map despite the shared depth boundary.
local directives = require("constants.vault_directives")

local handler = {}

-- At deeper Dungeon entrances the guard may be a sorcerer instead.
local function choose_priest(api)
    local monsters = api:absolute_depth() >= 10 and
        "w:1 orc sorcerer / orc priest" or "orc priest"

    api:emit(directives.MONS, monsters)
end

handler.choose_priest = choose_priest

return handler
