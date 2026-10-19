-- Ogre (SP_OGRE) is a selectable species with HP modifier 3 and XP factor 0.
-- Character creation projects its innate traits into player components; later
-- training consults aptitudes.

-- Source: crawl-ref/source/dat/species/ogre.yaml

local categories = require("constants.catalog")
local groups = require("constants.menu_groups")

local definition = {
    id = "SP_OGRE",
    monster_id = "MONS_OGRE",
    name = "Ogre",
    short_name = "Og",
    adjective = "Ogreish",
    selectable = true,
    difficulty = groups.SPECIES_INTERMEDIATE,
    difficulty_priority = 30,
    xp = 0,
    hp = 3,
    mp_mod = 0,
    mr = 4,
    strength = 11,
    intelligence = 9,
    dexterity = 4,
    levelup_stat_frequency = 3,
    levelup_stats = {
        "str",
    },
    -- Ogre changes training costs through these aptitudes; current skill levels
    -- are player state.
    aptitudes = {
        SK_AIR_MAGIC = {
            allowed = true,
            value = -1,
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
            value = -1,
        },
        SK_EARTH_MAGIC = {
            allowed = true,
            value = -1,
        },
        SK_EVOCATIONS = {
            allowed = true,
            value = -2,
        },
        SK_FIGHTING = {
            allowed = true,
            value = 3,
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
            allowed = true,
            value = 1,
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
            value = 0,
        },
        SK_RANGED_WEAPONS = {
            allowed = true,
            value = -3,
        },
        SK_SHIELDS = {
            allowed = true,
            value = 0,
        },
        SK_SHORT_BLADES = {
            allowed = true,
            value = -1,
        },
        SK_SPELLCASTING = {
            allowed = true,
            value = 1,
        },
        SK_STAVES = {
            allowed = true,
            value = 0,
        },
        SK_STEALTH = {
            allowed = true,
            value = -2,
        },
        SK_SUMMONINGS = {
            allowed = true,
            value = -1,
        },
        SK_THROWING = {
            allowed = true,
            value = 0,
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
            id = "MUT_TOUGH_SKIN",
            amount = 1,
        },
    },
    habitat = "HT_LAND",
    size = "SIZE_LARGE",
    undead_type = "US_ALIVE",
    recommended_jobs = {
        "JOB_GLADIATOR",
        "JOB_BERSERKER",
        "JOB_CINDER_ACOLYTE",
        "JOB_HEDGE_WIZARD",
        "JOB_AIR_ELEMENTALIST",
        "JOB_FIRE_ELEMENTALIST",
    },
    recommended_weapons = {
        "SK_MACES_FLAILS",
        "SK_POLEARMS",
        "SK_STAVES",
        "SK_AXES",
    },
    -- Source: crawl-ref/source/dat/descript/species.txt
    description = "Large, strong, and extremely robust, Ogres are competent at " ..
        "all forms of melee.\nNot merely brutes, they are also quite " ..
        "capable spellcasters.",
}

register.definition(categories.SPECIES, definition)

return definition
