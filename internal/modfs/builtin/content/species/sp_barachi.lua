-- Barachi (SP_BARACHI) is a selectable species with HP modifier 0 and XP
-- factor 0.
-- Character creation projects its innate traits into player components; later
-- training consults aptitudes.

-- Source: crawl-ref/source/dat/species/barachi.yaml

local categories = require("constants.catalog")
local groups = require("constants.menu_groups")

local definition = {
    id = "SP_BARACHI",
    monster_id = "MONS_BARACHI",
    name = "Barachi",
    short_name = "Ba",
    adjective = "Barachian",
    genus = "Frog",
    selectable = true,
    difficulty = groups.SPECIES_INTERMEDIATE,
    difficulty_priority = 20,
    xp = 0,
    hp = 0,
    mp_mod = 0,
    mr = 3,
    strength = 9,
    intelligence = 8,
    dexterity = 7,
    levelup_stat_frequency = 4,
    levelup_stats = {
        "str",
        "int",
        "dex",
    },
    -- Barachi changes training costs through these aptitudes; current skill levels
    -- are player state.
    aptitudes = {
        SK_AIR_MAGIC = {
            allowed = true,
            value = 1,
        },
        SK_ARMOUR = {
            allowed = true,
            value = 2,
        },
        SK_AXES = {
            allowed = true,
            value = 1,
        },
        SK_CONJURATIONS = {
            allowed = true,
            value = 1,
        },
        SK_DODGING = {
            allowed = true,
            value = 1,
        },
        SK_EARTH_MAGIC = {
            allowed = true,
            value = 0,
        },
        SK_EVOCATIONS = {
            allowed = true,
            value = 1,
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
            value = 1,
        },
        SK_ICE_MAGIC = {
            allowed = true,
            value = 2,
        },
        SK_INVOCATIONS = {
            allowed = true,
            value = -1,
        },
        SK_LONG_BLADES = {
            allowed = true,
            value = 2,
        },
        SK_MACES_FLAILS = {
            allowed = true,
            value = 1,
        },
        SK_NECROMANCY = {
            allowed = true,
            value = -1,
        },
        SK_POISON_MAGIC = {
            allowed = true,
            value = 1,
        },
        SK_POLEARMS = {
            allowed = true,
            value = 0,
        },
        SK_RANGED_WEAPONS = {
            allowed = true,
            value = 0,
        },
        SK_SHIELDS = {
            allowed = true,
            value = 1,
        },
        SK_SHORT_BLADES = {
            allowed = true,
            value = 1,
        },
        SK_SPELLCASTING = {
            allowed = true,
            value = 0,
        },
        SK_STAVES = {
            allowed = true,
            value = 1,
        },
        SK_STEALTH = {
            allowed = true,
            value = 0,
        },
        SK_SUMMONINGS = {
            allowed = true,
            value = 2,
        },
        SK_THROWING = {
            allowed = true,
            value = 0,
        },
        SK_TRANSLOCATIONS = {
            allowed = true,
            value = 1,
        },
        SK_TRANSMUTATIONS = {
            allowed = true,
            value = 1,
        },
        SK_UNARMED_COMBAT = {
            allowed = true,
            value = 1,
        },
    },
    mutations = {
        {
            level = 1,
            id = "MUT_DAYSTALKER",
            amount = 1,
        },
        {
            level = 1,
            id = "MUT_HOP",
            amount = 1,
        },
        {
            level = 1,
            id = "MUT_SLOW",
            amount = 1,
        },
        {
            level = 13,
            id = "MUT_HOP",
            amount = 1,
        },
    },
    flags = {
        "SPF_NO_HAIR",
    },
    habitat = "HT_WATER",
    size = "SIZE_MEDIUM",
    undead_type = "US_ALIVE",
    recommended_jobs = {
        "JOB_FIGHTER",
        "JOB_BERSERKER",
        "JOB_WARPER",
        "JOB_ARCANE_MARKSMAN",
        "JOB_SUMMONER",
        "JOB_ICE_ELEMENTALIST",
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
    description = "Barachim are slow-moving, amphibious humanoids who can hop " ..
        "long distances.\nTheir extended range of vision also allows " ..
        "them to be seen from further away.",
}

register.definition(categories.SPECIES, definition)

return definition
