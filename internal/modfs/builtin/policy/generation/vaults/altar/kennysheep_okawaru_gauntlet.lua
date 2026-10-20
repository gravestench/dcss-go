-- Theory of operation: Okawaru's gauntlet scales its single authored guard
-- with the branch. Depths uses a spriggan defender; Dungeon uses a goblin.
local branches = require("ids.branches")
local directives = require("constants.vault_directives")

local handler = {}

-- Keep the equipped monster specification attached to source glyph 1.
local function choose_guard(api)
    if api:branch_id() == branches.BRANCH_DEPTHS then
        api:emit(directives.KMONS,
            "1 = spriggan defender ; demon trident . robe . boomerang")
    else
        api:emit(directives.KMONS, "1 = goblin ; spear")
    end
end

handler.choose_guard = choose_guard

return handler
