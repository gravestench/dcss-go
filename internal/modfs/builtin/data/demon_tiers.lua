-- DCSS demon tiers are shared by summoned and vault-authored demons.
-- Keeping each source species in one table prevents the two selection
-- paths from drifting when a monster profile changes.
local monsters = require("ids.monsters")

local tiers = {
    [5] = {
        monsters.MONS_CRIMSON_IMP,
        monsters.MONS_QUASIT,
        monsters.MONS_WHITE_IMP,
        monsters.MONS_UFETUBUS,
        monsters.MONS_IRON_IMP,
        monsters.MONS_SHADOW_IMP,
    },

    [4] = {
        monsters.MONS_ICE_DEVIL,
        monsters.MONS_RUST_DEVIL,
        monsters.MONS_ORANGE_DEMON,
        monsters.MONS_RED_DEVIL,
        monsters.MONS_CHAOS_SPAWN,
        monsters.MONS_HELLWING,
    },

    [3] = {
        monsters.MONS_SUN_DEMON,
        monsters.MONS_SOUL_EATER,
        monsters.MONS_SMOKE_DEMON,
        monsters.MONS_NEQOXEC,
        monsters.MONS_YNOXINUL,
        monsters.MONS_SIXFIRHY,
    },

    [2] = {
        monsters.MONS_GREEN_DEATH,
        monsters.MONS_BLIZZARD_DEMON,
        monsters.MONS_BALRUG,
        monsters.MONS_CACODEMON,
        monsters.MONS_HELL_BEAST,
        monsters.MONS_HELLION,
        monsters.MONS_REAPER,
        monsters.MONS_LOROCYPROCA,
        monsters.MONS_TORMENTOR,
        monsters.MONS_SHADOW_DEMON,
    },

    [1] = {
        monsters.MONS_BRIMSTONE_FIEND,
        monsters.MONS_ICE_FIEND,
        monsters.MONS_TZITZIMITL,
        monsters.MONS_HELL_SENTINEL,
        monsters.MONS_EXECUTIONER,
    },
}

return tiers
