-- The chambered garden uses the same cold rewards and monster weighting
-- as the transporter map, but keeps its distinct DES room decisions.
local conditional = require("policy.generation.vaults.ice_cave.conditional")
local directives = require("constants.vault_directives")
local difficulty = require("policy.generation.vaults.ice_cave.difficulty")

local map = {}

-- The source declares the common slots before conditional substitutions.
function map.site_1(api)
    conditional.garden_start(api)
end

-- Hard rooms expose the stronger statue and more savage simulacra.
function map.site_2(api)
    conditional.garden_roster(api)

    if difficulty.hard(api) then
        api:emit(directives.NSUBST, "D = 3 / 1")
        api:emit(directives.SUBST, "E = 124, F = 4, 1 = 112, J = *")
        return
    end

    api:emit(directives.NSUBST,
        "1 = 2=1 / 4=1112.... / ., D = 2=3 / 1, 5 = 45 / 5")
end

return map
