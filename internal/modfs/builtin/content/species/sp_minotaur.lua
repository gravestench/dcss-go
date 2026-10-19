-- Minotaur (SP_MINOTAUR) is a selectable species with HP modifier 1 and XP
-- factor -1.
-- Character creation projects its innate traits into player components; later
-- training consults aptitudes.

-- Source: crawl-ref/source/dat/species/minotaur.yaml

local categories = require("constants.catalog")
local groups = require("constants.menu_groups")

local definition = {
    id = "SP_MINOTAUR",
    monster_id = "MONS_MINOTAUR",
    name = "Minotaur",
    short_name = "Mi",
    selectable = true,
    difficulty = groups.SPECIES_SIMPLE,
    difficulty_priority = 90,
    xp = -1,
    hp = 1,
    mp_mod = -1,
    mr = 3,
    strength = 12,
    intelligence = 5,
    dexterity = 5,
    levelup_stat_frequency = 4,
    levelup_stats = {
        "str",
        "dex",
    },
    -- Minotaur changes training costs through these aptitudes; current skill
    -- levels are player state.
    aptitudes = {
        SK_AIR_MAGIC = {
            allowed = true,
            value = -3,
        },
        SK_ARMOUR = {
            allowed = true,
            value = 2,
        },
        SK_AXES = {
            allowed = true,
            value = 2,
        },
        SK_CONJURATIONS = {
            allowed = true,
            value = -3,
        },
        SK_DODGING = {
            allowed = true,
            value = 1,
        },
        SK_EARTH_MAGIC = {
            allowed = true,
            value = -2,
        },
        SK_EVOCATIONS = {
            allowed = true,
            value = -1,
        },
        SK_FIGHTING = {
            allowed = true,
            value = 2,
        },
        SK_FIRE_MAGIC = {
            allowed = true,
            value = -3,
        },
        SK_HEXES = {
            allowed = true,
            value = -4,
        },
        SK_ICE_MAGIC = {
            allowed = true,
            value = -3,
        },
        SK_INVOCATIONS = {
            allowed = true,
            value = 0,
        },
        SK_LONG_BLADES = {
            allowed = true,
            value = 2,
        },
        SK_MACES_FLAILS = {
            allowed = true,
            value = 2,
        },
        SK_NECROMANCY = {
            allowed = true,
            value = -3,
        },
        SK_POISON_MAGIC = {
            allowed = true,
            value = -3,
        },
        SK_POLEARMS = {
            allowed = true,
            value = 2,
        },
        SK_RANGED_WEAPONS = {
            allowed = true,
            value = 1,
        },
        SK_SHIELDS = {
            allowed = true,
            value = 2,
        },
        SK_SHORT_BLADES = {
            allowed = true,
            value = 1,
        },
        SK_SPELLCASTING = {
            allowed = true,
            value = -4,
        },
        SK_STAVES = {
            allowed = true,
            value = 2,
        },
        SK_STEALTH = {
            allowed = true,
            value = -1,
        },
        SK_SUMMONINGS = {
            allowed = true,
            value = -3,
        },
        SK_THROWING = {
            allowed = true,
            value = 0,
        },
        SK_TRANSLOCATIONS = {
            allowed = true,
            value = -3,
        },
        SK_TRANSMUTATIONS = {
            allowed = true,
            value = -2,
        },
        SK_UNARMED_COMBAT = {
            allowed = true,
            value = 1,
        },
    },
    mutations = {
        {
            level = 1,
            id = "MUT_HORNS",
            amount = 2,
        },
        {
            level = 1,
            id = "MUT_REFLEXIVE_HEADBUTT",
            amount = 1,
        },
    },
    habitat = "HT_LAND",
    size = "SIZE_MEDIUM",
    undead_type = "US_ALIVE",
    recommended_jobs = {
        "JOB_FIGHTER",
        "JOB_GLADIATOR",
        "JOB_MONK",
        "JOB_HUNTER",
        "JOB_BERSERKER",
        "JOB_ABYSSAL_KNIGHT",
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
    description = "Minotaurs are large muscular humans with bovine heads. They " ..
        "excel at all forms\nof close and ranged combat.",
}

register.definition(categories.SPECIES, definition)

return definition
