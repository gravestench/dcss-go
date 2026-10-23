-- The source giant cave varies only two room glyphs by saved difficulty.
local directives = require("constants.vault_directives")
local difficulty = require("policy.generation.vaults.ice_cave.difficulty")

local map = {}

-- Hard caves add dangerous E/8 rooms; easy caves thin the F slots.
function map.site_4(api)
    if difficulty.hard(api) then
        api:emit(directives.NSUBST,
            "E8 = 2=7 / 7..., F = 6 / 5 / 2=5. / 4=12.. / .")
        return
    end

    api:emit(directives.NSUBST,
        "F = 556 / 2=5. / 2=12.. / .")
end

return map
