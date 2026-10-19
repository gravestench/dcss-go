local choice = require("policy.combat.monster_summons.choice")
local monsters = require("ids.monsters")

local eyeballs = {}

-- mon-cast.cc:SUMMON_EYEBALLS weights the five source eye kinds.
local kinds = {
    {
        id = monsters.MONS_FLOATING_EYE,
        weight = 100,
    },

    {
        id = monsters.MONS_GOLDEN_EYE,
        weight = 60,
    },

    {
        id = monsters.MONS_SHINING_EYE,
        weight = 40,
    },

    {
        id = monsters.MONS_GREAT_ORB_OF_EYES,
        weight = 20,
    },

    {
        id = monsters.MONS_EYE_OF_DEVASTATION,
        weight = 10,
    },
}

-- The spell's loop calls this once per intended summoned eye.
function eyeballs.pick(ctx)
    return choice.weighted(ctx, kinds)
end

return eyeballs
