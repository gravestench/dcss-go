-- Generated from the pinned DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/dat/species/merfolk.yaml

local categories = require("constants.catalog")

local definition = {
    id = "SP_MERFOLK",
    monster_id = "MONS_MERFOLK",
    name = "Merfolk",
    short_name = "Mf",
    adjective = "Merfolkian",
    selectable = true,
    difficulty = "Simple",
    difficulty_priority = 80,
    xp = 0,
    hp = 0,
    mp_mod = 0,
    mr = 3,
    strength = 8,
    intelligence = 7,
    dexterity = 9,
    levelup_stat_frequency = 5,
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
            value = -3,
        },
        SK_AXES = {
            allowed = true,
            value = -2,
        },
        SK_CONJURATIONS = {
            allowed = true,
            value = -2,
        },
        SK_DODGING = {
            allowed = true,
            value = 3,
        },
        SK_EARTH_MAGIC = {
            allowed = true,
            value = -2,
        },
        SK_EVOCATIONS = {
            allowed = true,
            value = 0,
        },
        SK_FIGHTING = {
            allowed = true,
            value = 1,
        },
        SK_FIRE_MAGIC = {
            allowed = true,
            value = -3,
        },
        SK_HEXES = {
            allowed = true,
            value = 0,
        },
        SK_ICE_MAGIC = {
            allowed = true,
            value = 1,
        },
        SK_INVOCATIONS = {
            allowed = true,
            value = 1,
        },
        SK_LONG_BLADES = {
            allowed = true,
            value = 2,
        },
        SK_MACES_FLAILS = {
            allowed = true,
            value = -2,
        },
        SK_NECROMANCY = {
            allowed = true,
            value = -2,
        },
        SK_POISON_MAGIC = {
            allowed = true,
            value = 1,
        },
        SK_POLEARMS = {
            allowed = true,
            value = 3,
        },
        SK_RANGED_WEAPONS = {
            allowed = true,
            value = -2,
        },
        SK_SHIELDS = {
            allowed = true,
            value = 0,
        },
        SK_SHORT_BLADES = {
            allowed = true,
            value = 2,
        },
        SK_SPELLCASTING = {
            allowed = true,
            value = -1,
        },
        SK_STAVES = {
            allowed = true,
            value = -2,
        },
        SK_STEALTH = {
            allowed = true,
            value = 2,
        },
        SK_SUMMONINGS = {
            allowed = true,
            value = 0,
        },
        SK_THROWING = {
            allowed = true,
            value = 0,
        },
        SK_TRANSLOCATIONS = {
            allowed = true,
            value = -2,
        },
        SK_TRANSMUTATIONS = {
            allowed = true,
            value = 3,
        },
        SK_UNARMED_COMBAT = {
            allowed = true,
            value = 1,
        },
    },
    mutations = {
        {
            level = 1,
            id = "MUT_MERTAIL",
            amount = 1,
        },
        {
            level = 1,
            id = "MUT_NIMBLE_SWIMMER",
            amount = 2,
        },
    },
    habitat = "HT_WATER",
    size = "SIZE_MEDIUM",
    undead_type = "US_ALIVE",
    recommended_jobs = {
        "JOB_GLADIATOR",
        "JOB_BERSERKER",
        "JOB_TRANSMUTER",
        "JOB_SUMMONER",
        "JOB_ICE_ELEMENTALIST",
        "JOB_VENOM_MAGE",
    },
    recommended_weapons = {
        "SK_POLEARMS",
        "SK_LONG_BLADES",
    },
}

register.definition(categories.SPECIES, definition)

return definition
