-- Kobold (SP_KOBOLD) is a selectable species with HP modifier -2 and XP
-- factor 1.
-- Character creation projects its innate traits into player components; later
-- training consults aptitudes.

-- Source: crawl-ref/source/dat/species/kobold.yaml

local categories = require("constants.catalog")
local groups = require("constants.menu_groups")

local definition = {
    id = "SP_KOBOLD",
    monster_id = "MONS_KOBOLD",
    name = "Kobold",
    short_name = "Ko",
    selectable = true,
    difficulty = groups.SPECIES_INTERMEDIATE,
    difficulty_priority = 90,
    xp = 1,
    hp = -2,
    mp_mod = 0,
    mr = 3,
    strength = 5,
    intelligence = 9,
    dexterity = 10,
    levelup_stat_frequency = 5,
    levelup_stats = {
        "str",
        "int",
        "dex",
    },
    -- Kobold changes training costs through these aptitudes; current skill levels
    -- are player state.
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
            value = -2,
        },
        SK_CONJURATIONS = {
            allowed = true,
            value = 0,
        },
        SK_DODGING = {
            allowed = true,
            value = 2,
        },
        SK_EARTH_MAGIC = {
            allowed = true,
            value = 0,
        },
        SK_EVOCATIONS = {
            allowed = true,
            value = 2,
        },
        SK_FIGHTING = {
            allowed = true,
            value = 1,
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
            value = -2,
        },
        SK_MACES_FLAILS = {
            allowed = true,
            value = -1,
        },
        SK_NECROMANCY = {
            allowed = true,
            value = 0,
        },
        SK_POISON_MAGIC = {
            allowed = true,
            value = 0,
        },
        SK_POLEARMS = {
            allowed = true,
            value = -2,
        },
        SK_RANGED_WEAPONS = {
            allowed = true,
            value = 3,
        },
        SK_SHIELDS = {
            allowed = true,
            value = -2,
        },
        SK_SHORT_BLADES = {
            allowed = true,
            value = 3,
        },
        SK_SPELLCASTING = {
            allowed = true,
            value = 0,
        },
        SK_STAVES = {
            allowed = true,
            value = -1,
        },
        SK_STEALTH = {
            allowed = true,
            value = 4,
        },
        SK_SUMMONINGS = {
            allowed = true,
            value = 0,
        },
        SK_THROWING = {
            allowed = true,
            value = 1,
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
            id = "MUT_NIGHTSTALKER",
            amount = 3,
        },
    },
    habitat = "HT_LAND",
    size = "SIZE_SMALL",
    undead_type = "US_ALIVE",
    recommended_jobs = {
        "JOB_BRIGAND",
        "JOB_BERSERKER",
        "JOB_ARCANE_MARKSMAN",
        "JOB_ENCHANTER",
        "JOB_CONJURER",
        "JOB_SUMMONER",
    },
    recommended_weapons = {
        "SK_SHORT_BLADES",
        "SK_MACES_FLAILS",
        "SK_STAVES",
    },
    -- Source: crawl-ref/source/dat/descript/species.txt
    description = "Kobolds are attuned to the shadows and can only see or be " ..
        "seen at a close range.\nThey are small and a little fragile, " ..
        "and are talented in most skills.",
}

register.definition(categories.SPECIES, definition)

return definition
