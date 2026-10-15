-- Generated from the pinned DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/dat/species/naga.yaml

local categories = require("constants.catalog")

local definition = {
    id = "SP_NAGA",
    monster_id = "MONS_NAGA",
    name = "Naga",
    short_name = "Na",
    selectable = true,
    difficulty = "Advanced",
    difficulty_priority = 60,
    xp = 0,
    hp = 2,
    mp_mod = 0,
    mr = 5,
    strength = 10,
    intelligence = 8,
    dexterity = 6,
    levelup_stat_frequency = 4,
    levelup_stats = {
        "str",
        "int",
        "dex",
    },
    aptitudes = {
        SK_AIR_MAGIC = {
            allowed = true,
            value = 0,
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
            value = 0,
        },
        SK_DODGING = {
            allowed = true,
            value = -2,
        },
        SK_EARTH_MAGIC = {
            allowed = true,
            value = 0,
        },
        SK_EVOCATIONS = {
            allowed = true,
            value = 0,
        },
        SK_FIGHTING = {
            allowed = true,
            value = 0,
        },
        SK_FIRE_MAGIC = {
            allowed = true,
            value = 0,
        },
        SK_HEXES = {
            allowed = true,
            value = 0,
        },
        SK_ICE_MAGIC = {
            allowed = true,
            value = 0,
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
            value = 3,
        },
        SK_POLEARMS = {
            allowed = true,
            value = 0,
        },
        SK_RANGED_WEAPONS = {
            allowed = true,
            value = -1,
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
            value = 5,
        },
        SK_SUMMONINGS = {
            allowed = true,
            value = 0,
        },
        SK_THROWING = {
            allowed = true,
            value = -1,
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
            id = "MUT_CONSTRICTING_TAIL",
            amount = 1,
        },
        {
            level = 1,
            id = "MUT_DEFORMED",
            amount = 1,
        },
        {
            level = 1,
            id = "MUT_POISON_RESISTANCE",
            amount = 1,
        },
        {
            level = 1,
            id = "MUT_SLOW",
            amount = 2,
        },
        {
            level = 1,
            id = "MUT_SPIT_POISON",
            amount = 1,
        },
        {
            level = 13,
            id = "MUT_CONSTRICTING_TAIL",
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
        "JOB_BERSERKER",
        "JOB_TRANSMUTER",
        "JOB_ENCHANTER",
        "JOB_FIRE_ELEMENTALIST",
        "JOB_ICE_ELEMENTALIST",
        "JOB_WARPER",
        "JOB_HEDGE_WIZARD",
        "JOB_VENOM_MAGE",
    },
    recommended_weapons = {
        "SK_LONG_BLADES",
        "SK_AXES",
        "SK_MACES_FLAILS",
        "SK_POLEARMS",
        "SK_STAVES",
        "SK_RANGED_WEAPONS",
    },
    walking_verb = "Slither",
    altar_action = "coil in front of",
}

register.definition(categories.SPECIES, definition)

return definition
