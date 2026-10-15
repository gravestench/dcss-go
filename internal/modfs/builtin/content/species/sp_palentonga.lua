-- Generated from the pinned DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/dat/species/palentonga.yaml

local categories = require("constants.catalog")

local definition = {
    id = "SP_PALENTONGA",
    monster_id = "MONS_PALENTONGA",
    name = "Palentonga",
    short_name = "Pa",
    selectable = true,
    difficulty = "Simple",
    difficulty_priority = 60,
    xp = -1,
    hp = 0,
    mp_mod = 0,
    mr = 3,
    strength = 13,
    intelligence = 8,
    dexterity = 5,
    levelup_stat_frequency = 4,
    levelup_stats = {
        "str",
        "int",
        "dex",
    },
    aptitudes = {
        SK_AIR_MAGIC = {
            allowed = true,
            value = -2,
        },
        SK_ARMOUR = {
            allowed = true,
            value = -2,
        },
        SK_AXES = {
            allowed = true,
            value = 0,
        },
        SK_CONJURATIONS = {
            allowed = true,
            value = -1,
        },
        SK_DODGING = {
            allowed = true,
            value = -2,
        },
        SK_EARTH_MAGIC = {
            allowed = true,
            value = -1,
        },
        SK_EVOCATIONS = {
            allowed = true,
            value = -1,
        },
        SK_FIGHTING = {
            allowed = true,
            value = 0,
        },
        SK_FIRE_MAGIC = {
            allowed = true,
            value = -2,
        },
        SK_HEXES = {
            allowed = true,
            value = 0,
        },
        SK_ICE_MAGIC = {
            allowed = true,
            value = -2,
        },
        SK_INVOCATIONS = {
            allowed = true,
            value = 1,
        },
        SK_LONG_BLADES = {
            allowed = true,
            value = 0,
        },
        SK_MACES_FLAILS = {
            allowed = true,
            value = 0,
        },
        SK_NECROMANCY = {
            allowed = true,
            value = 0,
        },
        SK_POISON_MAGIC = {
            allowed = true,
            value = -2,
        },
        SK_POLEARMS = {
            allowed = true,
            value = -1,
        },
        SK_RANGED_WEAPONS = {
            allowed = true,
            value = -2,
        },
        SK_SHIELDS = {
            allowed = true,
            value = -1,
        },
        SK_SHORT_BLADES = {
            allowed = true,
            value = 0,
        },
        SK_SPELLCASTING = {
            allowed = true,
            value = -1,
        },
        SK_STAVES = {
            allowed = true,
            value = 0,
        },
        SK_STEALTH = {
            allowed = true,
            value = -3,
        },
        SK_SUMMONINGS = {
            allowed = true,
            value = -2,
        },
        SK_THROWING = {
            allowed = true,
            value = -3,
        },
        SK_TRANSLOCATIONS = {
            allowed = true,
            value = 0,
        },
        SK_TRANSMUTATIONS = {
            allowed = true,
            value = 0,
        },
        SK_UNARMED_COMBAT = {
            allowed = true,
            value = 0,
        },
    },
    mutations = {
        {
            level = 1,
            id = "MUT_ACUTE_VISION",
            amount = 1,
        },
        {
            level = 1,
            id = "MUT_ARMOURED_TAIL",
            amount = 1,
        },
        {
            level = 1,
            id = "MUT_DEFORMED",
            amount = 1,
        },
        {
            level = 1,
            id = "MUT_ROLL",
            amount = 1,
        },
        {
            level = 1,
            id = "MUT_RUGGED_BROWN_SCALES",
            amount = 3,
        },
        {
            level = 7,
            id = "MUT_CURL",
            amount = 1,
        },
    },
    flags = {
        "SPF_BARDING",
        "SPF_SMALL_TORSO",
    },
    habitat = "HT_LAND",
    size = "SIZE_LARGE",
    undead_type = "US_ALIVE",
    recommended_jobs = {
        "JOB_FIGHTER",
        "JOB_BERSERKER",
        "JOB_ABYSSAL_KNIGHT",
        "JOB_WARPER",
        "JOB_HEDGE_WIZARD",
    },
    recommended_weapons = {
        "SK_UNARMED_COMBAT",
        "SK_MACES_FLAILS",
        "SK_AXES",
        "SK_STAVES",
    },
}

register.definition(categories.SPECIES, definition)

return definition
