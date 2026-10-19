local choice = require("policy.combat.monster_summons.choice")
local monsters = require("ids.monsters")
local streams = require("constants.rng_streams")

local demons = {}

-- mon-place.cc:random_demon_by_tier lists each source kind once. Higher
-- tier numbers mean weaker demons in DCSS's classification.
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

-- One uniform draw picks inside the requested tier. A missing tier is a
-- rule error rather than an implicit fallback to unrelated demons.
function demons.tier(ctx, tier)
    local kinds = tiers[tier]

    if not kinds then
        error("unsupported source demon tier " .. tostring(tier))
    end

    return choice.uniform(ctx, kinds)
end

-- Source summon_any_demon picks a common tier-four demon sixty percent
-- of the time and a tier-three demon otherwise.
function demons.common(ctx)
    local tier = ctx:random(streams.MONSTER_SPELL, 10) < 6 and 4 or 3

    return demons.tier(ctx, tier)
end

-- Greater demons use the same sixty/forty split between tiers two and one.
function demons.greater(ctx)
    local tier = ctx:random(streams.MONSTER_SPELL, 10) < 6 and 2 or 1

    return demons.tier(ctx, tier)
end

return demons
