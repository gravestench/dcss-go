-- Theory of operation: Hepliaklqana's altar stages a living group beside
-- spectral ancestors. The source map uses four MONS slots and one D guard;
-- the complete group changes together between Dungeon and Depths.
local branches = require("ids.branches")
local directives = require("constants.vault_directives")

local handler = {}

-- Preserve slot order so the map's 1–7 and D shuffle still pairs the
-- intended living and spectral monsters after its branch choice.
local function choose_ancestors(api)
    if api:branch_id() == branches.BRANCH_DEPTHS then
        api:emit(directives.MONS,
            "deep troll earth mage, spectral deep troll earth mage, tengu reaver")
        api:emit(directives.MONS,
            "spectral tengu reaver, spriggan defender, spectral spriggan defender")
        api:emit(directives.MONS, "hell knight")
        api:emit(directives.KMONS, "D = spectral hell knight")
    else
        api:emit(directives.MONS,
            "goblin, spectral goblin, kobold, spectral kobold, hobgoblin")
        api:emit(directives.MONS, "spectral hobgoblin, orc")
        api:emit(directives.KMONS, "D = spectral orc")
    end
end

handler.choose_ancestors = choose_ancestors

return handler
