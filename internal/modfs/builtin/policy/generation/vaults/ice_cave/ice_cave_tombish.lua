-- This tomb uses the common undead roster but changes its named boss.
local directives = require("constants.vault_directives")
local difficulty = require("policy.generation.vaults.ice_cave.difficulty")
local monsters = require("policy.generation.vaults.ice_cave.monsters")

local map = {}

-- Source code calls the undead helper inside each branch before the
-- map-specific KMONS and room substitutions; preserve that ordering.
function map.site_4(api)
    monsters.undead(api)

    if difficulty.hard(api) then
        api:emit(directives.KMONS,
            "D7 = reaper ; halberd itemname:scythe " ..
            "tile:wpn_scythe wtile:scythe ego:freezing")
        api:emit(directives.SHUFFLE, "D7 / 88")
        api:emit(directives.NSUBST, "7 = 7 / 7.., 8 = 8 / 8. / .")
        api:emit(directives.NSUBST, "4 = 6 / 446, F = 122445")
        return
    end

    api:emit(directives.KMONS, "D = necromancer")
    api:emit(directives.SHUFFLE, "D7 / 88")
    api:emit(directives.NSUBST, "7 = 7 / ., 8 = 8 / .")
    api:emit(directives.SUBST, "4 = 4:70 6, F = .12244")
end

return map
