-- The necromancer vault promotes its final guardian to a lich when hard.
local directives = require("constants.vault_directives")
local difficulty = require("policy.generation.vaults.ice_cave.difficulty")

local map = {}

-- Preserve the source's order: define E before reassigning D and K.
function map.site_4(api)
    if difficulty.hard(api) then
        api:emit(directives.KMONS, "E = lich")
        api:emit(directives.SUBST, "D = E, K = D")
        return
    end

    api:emit(directives.SUBST, "K = 5")
end

return map
