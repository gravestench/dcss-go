local choice = require("policy.combat.monster_summons.choice")
local monsters = require("ids.monsters")

local holies = {}

-- mon-cast.cc:SUMMON_HOLIES makes an Ophan rare beside angels and cherubim.
local kinds = {
    {
        id = monsters.MONS_ANGEL,
        weight = 100,
    },

    {
        id = monsters.MONS_CHERUB,
        weight = 80,
    },

    {
        id = monsters.MONS_DAEVA,
        weight = 50,
    },

    {
        id = monsters.MONS_OPHAN,
        weight = 1,
    },
}

-- Keep this picker independent of the spell's count and duration rules.
function holies.pick(ctx)
    return choice.weighted(ctx, kinds)
end

return holies
