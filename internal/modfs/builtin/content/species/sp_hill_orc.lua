-- Generated from the pinned DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/dat/species/hill-orc.yaml

local categories = require("constants.catalog")
local groups = require("constants.menu_groups")

local definition = {
    id = "SP_HILL_ORC",
    monster_id = "MONS_ORC",
    name = "Hill Orc",
    short_name = "HO",
    selectable = true,
    difficulty = groups.SPECIES_SIMPLE,
    difficulty_priority = 100,
    xp = 0,
    hp = 1,
    mp_mod = 0,
    mr = 3,
    strength = 10,
    intelligence = 8,
    dexterity = 6,
    levelup_stat_frequency = 5,
    levelup_stats = {
        "str",
    },
    aptitudes = {
        SK_AIR_MAGIC = {
            allowed = true,
            value = -2,
        },
        SK_ARMOUR = {
            allowed = true,
            value = 1,
        },
        SK_AXES = {
            allowed = true,
            value = 3,
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
            value = 2,
        },
        SK_FIRE_MAGIC = {
            allowed = true,
            value = 1,
        },
        SK_HEXES = {
            allowed = true,
            value = 0,
        },
        SK_ICE_MAGIC = {
            allowed = true,
            value = -1,
        },
        SK_INVOCATIONS = {
            allowed = true,
            value = 3,
        },
        SK_LONG_BLADES = {
            allowed = true,
            value = 1,
        },
        SK_MACES_FLAILS = {
            allowed = true,
            value = 1,
        },
        SK_NECROMANCY = {
            allowed = true,
            value = 0,
        },
        SK_POISON_MAGIC = {
            allowed = true,
            value = -1,
        },
        SK_POLEARMS = {
            allowed = true,
            value = 1,
        },
        SK_RANGED_WEAPONS = {
            allowed = true,
            value = -1,
        },
        SK_SHIELDS = {
            allowed = true,
            value = 1,
        },
        SK_SHORT_BLADES = {
            allowed = true,
            value = 0,
        },
        SK_SPELLCASTING = {
            allowed = true,
            value = -3,
        },
        SK_STAVES = {
            allowed = true,
            value = -1,
        },
        SK_STEALTH = {
            allowed = true,
            value = -1,
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
            value = -2,
        },
        SK_TRANSMUTATIONS = {
            allowed = true,
            value = -3,
        },
        SK_UNARMED_COMBAT = {
            allowed = true,
            value = 1,
        },
    },
    habitat = "HT_LAND",
    size = "SIZE_MEDIUM",
    undead_type = "US_ALIVE",
    recommended_jobs = {
        "JOB_FIGHTER",
        "JOB_MONK",
        "JOB_BERSERKER",
        "JOB_ABYSSAL_KNIGHT",
        "JOB_CINDER_ACOLYTE",
        "JOB_FIRE_ELEMENTALIST",
    },
    recommended_weapons = {
        "SK_MACES_FLAILS",
        "SK_AXES",
        "SK_POLEARMS",
    },
    -- Source: crawl-ref/source/dat/descript/species.txt
    description = "Hill Orcs are skilled in close combat, and often dabble in " ..
        "offensive magic. Only\nthey may worship the Orc god Beogh.",
}

register.definition(categories.SPECIES, definition)

return definition
