-- The demon cave's statue and room shuffles depend on entrance difficulty.
local directives = require("constants.vault_directives")
local difficulty = require("policy.generation.vaults.ice_cave.difficulty")

local map = {}

-- Keep SHUFFLE before NSUBST so the parsed DES applies the source order.
function map.site_3(api)
    if difficulty.hard(api) then
        api:emit(directives.KMONS, "D = orange crystal statue")
        api:emit(directives.SHUFFLE, "EF / 8H")
        api:emit(directives.NSUBST,
            "3 = 3 / D4, F = E / E.., H = 8. / .")
        return
    end

    api:emit(directives.SUBST, "6 = 56")
end

return map
