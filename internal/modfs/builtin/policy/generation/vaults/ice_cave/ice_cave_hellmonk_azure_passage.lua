-- The azure passage imports its source Jiyva-flavoured roster. Its DES
-- retains the original markers and geometry; the hook selects actors.
local directives = require("constants.vault_directives")
local difficulty = require("policy.generation.vaults.ice_cave.difficulty")
local monsters = require("policy.generation.vaults.ice_cave.monsters")

local map = {}

-- Hard caves add stronger Jiyva creatures and simulacra. The random-list
-- record is used by later effects and does not immediately place actors.
function map.site_2(api)
    if difficulty.hard(api) then
        api:emit(directives.MONS,
            "glowing shapeshifter simulacrum / slime creature simulacrum" ..
            " / great orb of eyes simulacrum")
        api:emit(directives.MONS,
            "orange crystal statue, slime creature band, quicksilver ooze")
        api:emit(directives.MONS, "azure jelly, rockslime")
        monsters.record_random_list(api,
            "glowing shapeshifter simulacrum w:20" ..
            " / slime creature simulacrum w:20" ..
            " / great orb of eyes simulacrum w:20" ..
            " / slime creature w:40 / quicksilver ooze w:20" ..
            " / azure jelly")
        api:emit(directives.SUBST, "p = 4, q = 455, r = 5, s = 6")
        return
    end

    api:emit(directives.MONS,
        "shapeshifter simulacrum / glowing shapeshifter simulacrum" ..
        " / slime creature simulacrum / great orb of eyes simulacrum")
    api:emit(directives.MONS,
        "ice statue, slime creature band, quicksilver ooze, azure jelly")
    monsters.record_random_list(api,
        "shapeshifter simulacrum / glowing shapeshifter simulacrum" ..
        " / slime creature simulacrum / great orb of eyes simulacrum" ..
        " / slime creature w:20 / quicksilver ooze")
    api:emit(directives.SUBST, "q = 34455")
end

return map
