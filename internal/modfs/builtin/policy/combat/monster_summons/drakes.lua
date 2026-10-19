local choice = require("policy.combat.monster_summons.choice")
local monsters = require("ids.monsters")

local drakes = {}

-- mon-cast.cc:_pick_drake weights the six source drake and lizard kinds.
local kinds = {
    {
        id = monsters.MONS_SWAMP_DRAKE,
        weight = 5,
    },

    {
        id = monsters.MONS_KOMODO_DRAGON,
        weight = 5,
    },

    {
        id = monsters.MONS_WIND_DRAKE,
        weight = 5,
    },

    {
        id = monsters.MONS_RIME_DRAKE,
        weight = 6,
    },

    {
        id = monsters.MONS_DEATH_DRAKE,
        weight = 6,
    },

    {
        id = monsters.MONS_LINDWURM,
        weight = 3,
    },
}

-- Draw one source kind before spawn; placement can then fail independently.
function drakes.pick(ctx)
    return choice.weighted(ctx, kinds)
end

return drakes
