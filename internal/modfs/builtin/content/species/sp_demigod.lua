-- Demigod (SP_DEMIGOD) is a selectable species with HP modifier 1 and XP
-- factor -2.
-- Character creation projects its innate traits into player components; later
-- training consults aptitudes.

-- Source: crawl-ref/source/dat/species/demigod.yaml

local categories = require("constants.catalog")
local groups = require("constants.menu_groups")

local definition = {
    id = "SP_DEMIGOD",
    monster_id = "MONS_DEMIGOD",
    name = "Demigod",
    short_name = "Dg",
    adjective = "Divine",
    selectable = true,
    difficulty = groups.SPECIES_ADVANCED,
    difficulty_priority = 80,
    xp = -2,
    hp = 1,
    mp_mod = 2,
    mr = 4,
    strength = 9,
    intelligence = 10,
    dexterity = 9,
    levelup_stat_frequency = 28,
    levelup_stats = mod.null,
    -- Demigod changes training costs through these aptitudes; current skill levels
    -- are player state.
    aptitudes = {
        SK_AIR_MAGIC = {
            allowed = true,
            value = -1,
        },
        SK_ARMOUR = {
            allowed = true,
            value = -1,
        },
        SK_AXES = {
            allowed = true,
            value = -1,
        },
        SK_CONJURATIONS = {
            allowed = true,
            value = -1,
        },
        SK_DODGING = {
            allowed = true,
            value = -1,
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
            value = -1,
        },
        SK_FIRE_MAGIC = {
            allowed = true,
            value = -1,
        },
        SK_HEXES = {
            allowed = true,
            value = -1,
        },
        SK_ICE_MAGIC = {
            allowed = true,
            value = -1,
        },
        SK_INVOCATIONS = {
            allowed = false,
            value = 0,
        },
        SK_LONG_BLADES = {
            allowed = true,
            value = -1,
        },
        SK_MACES_FLAILS = {
            allowed = true,
            value = -1,
        },
        SK_NECROMANCY = {
            allowed = true,
            value = -1,
        },
        SK_POISON_MAGIC = {
            allowed = true,
            value = -1,
        },
        SK_POLEARMS = {
            allowed = true,
            value = -1,
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
            value = -1,
        },
        SK_SPELLCASTING = {
            allowed = true,
            value = -2,
        },
        SK_STAVES = {
            allowed = true,
            value = -1,
        },
        SK_STEALTH = {
            allowed = true,
            value = 0,
        },
        SK_SUMMONINGS = {
            allowed = true,
            value = -1,
        },
        SK_THROWING = {
            allowed = true,
            value = -1,
        },
        SK_TRANSLOCATIONS = {
            allowed = true,
            value = -1,
        },
        SK_TRANSMUTATIONS = {
            allowed = true,
            value = -1,
        },
        SK_UNARMED_COMBAT = {
            allowed = true,
            value = -1,
        },
    },
    mutations = {
        {
            level = 1,
            id = "MUT_DIVINE_ATTRS",
            amount = 1,
        },
        {
            level = 1,
            id = "MUT_FORLORN",
            amount = 1,
        },
        {
            level = 1,
            id = "MUT_HIGH_MAGIC",
            amount = 1,
        },
    },
    habitat = "HT_LAND",
    size = "SIZE_MEDIUM",
    undead_type = "US_ALIVE",
    recommended_jobs = {
        "JOB_TRANSMUTER",
        "JOB_CONJURER",
        "JOB_FIRE_ELEMENTALIST",
        "JOB_ICE_ELEMENTALIST",
        "JOB_AIR_ELEMENTALIST",
        "JOB_EARTH_ELEMENTALIST",
    },
    recommended_weapons = {
        "SK_LONG_BLADES",
        "SK_AXES",
        "SK_MACES_FLAILS",
        "SK_POLEARMS",
        "SK_STAVES",
        "SK_RANGED_WEAPONS",
    },
    -- Source: crawl-ref/source/dat/descript/species.txt
    description = "Demigods refuse to worship any god, but make up for this " ..
        "with divine attributes\nand high reserves of health and " ..
        "magic.",
}

register.definition(categories.SPECIES, definition)

return definition
