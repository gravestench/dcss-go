-- Lava-maze helper tags are static DES tags so the catalog can select a
-- helper before its hook runs. Source setup also chooses monster glyphs
-- and clears stair placeholders after each helper's own directives.
local directives = require("constants.vault_directives")

local shared = {}

-- Emit the source monster substitutions before clearing helper stair slots.
local function setup(api, monsters)
    if monsters then
        api:emit(directives.SUBST, "0 = ..009")
        api:emit(directives.SUBST, "9 = 998")
    end

    api:emit(directives.CLEAR, "_")
end

-- Quiet helpers keep their authored monster glyphs and clear unused stairs.
function shared.setup_quiet(api)
    setup(api, false)
end

-- Populated helpers add standard lava-maze monsters before clearing stairs.
function shared.setup_monsters(api)
    setup(api, true)
end

return shared
