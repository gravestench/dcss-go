-- The transporter garden has the shared statue roster but unique portal
-- geometry. Its transporter markers stay in the original DES positions.
local conditional = require("policy.generation.vaults.ice_cave.conditional")
local directives = require("constants.vault_directives")
local difficulty = require("policy.generation.vaults.ice_cave.difficulty")

local map = {}

-- Seed loot and two simulacrum slots before reading the later room rules.
function map.site_1(api)
    conditional.garden_start(api)
end

-- Difficulty changes statue quality and how often the central rooms
-- populate. The random-list weights are shared with the chambered garden.
function map.site_2(api)
    conditional.garden_roster(api)

    if difficulty.hard(api) then
        api:emit(directives.SUBST, "1 = 112, 3 = 4, D = 3, E = *")
        api:emit(directives.NSUBST, "% = * / %")
        return
    end

    api:emit(directives.NSUBST,
        "1 = 2=1 / 4=1112.... / ., 5 = 45 / 5")
    api:emit(directives.SUBST, "D = *")
end

return map
