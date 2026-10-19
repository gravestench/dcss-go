local choice = require("policy.combat.monster_summons.choice")
local monsters = require("ids.monsters")

local vermin = {}

-- mon-cast.cc:_pick_vermin favors hell rats over the rarer crawlers.
local kinds = {
    {
        id = monsters.MONS_HELL_RAT,
        weight = 8,
    },

    {
        id = monsters.MONS_REDBACK,
        weight = 5,
    },

    {
        id = monsters.MONS_TARANTELLA,
        weight = 2,
    },

    {
        id = monsters.MONS_JUMPING_SPIDER,
        weight = 2,
    },

    {
        id = monsters.MONS_DEMONIC_CRAWLER,
        weight = 3,
    },
}

-- A single source draw chooses each attempted summon independently.
function vermin.pick(ctx)
    return choice.weighted(ctx, kinds)
end

return vermin
