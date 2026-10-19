-- Spriggan (SP_SPRIGGAN) is a selectable species with HP modifier -3 and XP
-- factor -1.
-- Character creation projects its innate traits into player components; later
-- training consults aptitudes.

-- Source: crawl-ref/source/dat/species/spriggan.yaml

local categories = require("constants.catalog")
local groups = require("constants.menu_groups")

local definition = {
    id = "SP_SPRIGGAN",
    monster_id = "MONS_SPRIGGAN",
    name = "Spriggan",
    short_name = "Sp",
    selectable = true,
    difficulty = groups.SPECIES_INTERMEDIATE,
    difficulty_priority = 60,
    xp = -1,
    hp = -3,
    mp_mod = 1,
    mr = 7,
    strength = 4,
    intelligence = 9,
    dexterity = 10,
    levelup_stat_frequency = 5,
    levelup_stats = {
        "int",
        "dex",
    },
    -- Spriggan changes training costs through these aptitudes; current skill
    -- levels are player state.
    aptitudes = {
        SK_AIR_MAGIC = {
            allowed = true,
            value = -1,
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
            value = -3,
        },
        SK_DODGING = {
            allowed = true,
            value = 3,
        },
        SK_EARTH_MAGIC = {
            allowed = true,
            value = -1,
        },
        SK_EVOCATIONS = {
            allowed = true,
            value = 3,
        },
        SK_FIGHTING = {
            allowed = true,
            value = -2,
        },
        SK_FIRE_MAGIC = {
            allowed = true,
            value = -2,
        },
        SK_HEXES = {
            allowed = true,
            value = 2,
        },
        SK_ICE_MAGIC = {
            allowed = true,
            value = -2,
        },
        SK_INVOCATIONS = {
            allowed = true,
            value = 0,
        },
        SK_LONG_BLADES = {
            allowed = true,
            value = -2,
        },
        SK_MACES_FLAILS = {
            allowed = true,
            value = -3,
        },
        SK_NECROMANCY = {
            allowed = true,
            value = -1,
        },
        SK_POISON_MAGIC = {
            allowed = true,
            value = 0,
        },
        SK_POLEARMS = {
            allowed = true,
            value = -3,
        },
        SK_RANGED_WEAPONS = {
            allowed = true,
            value = 0,
        },
        SK_SHIELDS = {
            allowed = true,
            value = -3,
        },
        SK_SHORT_BLADES = {
            allowed = true,
            value = 1,
        },
        SK_SPELLCASTING = {
            allowed = true,
            value = 2,
        },
        SK_STAVES = {
            allowed = true,
            value = -3,
        },
        SK_STEALTH = {
            allowed = true,
            value = 5,
        },
        SK_SUMMONINGS = {
            allowed = true,
            value = -2,
        },
        SK_THROWING = {
            allowed = true,
            value = 0,
        },
        SK_TRANSLOCATIONS = {
            allowed = true,
            value = 4,
        },
        SK_TRANSMUTATIONS = {
            allowed = true,
            value = 3,
        },
        SK_UNARMED_COMBAT = {
            allowed = true,
            value = -2,
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
            id = "MUT_FAST",
            amount = 3,
        },
    },
    habitat = "HT_LAND",
    size = "SIZE_LITTLE",
    undead_type = "US_ALIVE",
    recommended_jobs = {
        "JOB_BRIGAND",
        "JOB_ARTIFICER",
        "JOB_ABYSSAL_KNIGHT",
        "JOB_WARPER",
        "JOB_ENCHANTER",
        "JOB_CONJURER",
        "JOB_EARTH_ELEMENTALIST",
        "JOB_VENOM_MAGE",
    },
    recommended_weapons = {
        "SK_SHORT_BLADES",
    },
    -- Source: crawl-ref/source/dat/descript/species.txt
    description = "Very small, very frail and very fast, Spriggans are highly " ..
        "competent stabbers\nand spellcasters.",
}

register.definition(categories.SPECIES, definition)

return definition
