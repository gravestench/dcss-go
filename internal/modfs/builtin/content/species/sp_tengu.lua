-- Tengu (SP_TENGU) is a selectable species with HP modifier -2 and XP factor
-- 0.
-- Character creation projects its innate traits into player components; later
-- training consults aptitudes.

-- Source: crawl-ref/source/dat/species/tengu.yaml

local categories = require("constants.catalog")
local groups = require("constants.menu_groups")

local definition = {
    id = "SP_TENGU",
    monster_id = "MONS_TENGU",
    name = "Tengu",
    short_name = "Te",
    selectable = true,
    difficulty = groups.SPECIES_INTERMEDIATE,
    difficulty_priority = 50,
    xp = 0,
    hp = -2,
    mp_mod = 1,
    mr = 3,
    strength = 8,
    intelligence = 8,
    dexterity = 9,
    levelup_stat_frequency = 4,
    levelup_stats = {
        "str",
        "int",
        "dex",
    },
    -- Tengu changes training costs through these aptitudes; current skill levels
    -- are player state.
    aptitudes = {
        SK_AIR_MAGIC = {
            allowed = true,
            value = 3,
        },
        SK_ARMOUR = {
            allowed = true,
            value = 1,
        },
        SK_AXES = {
            allowed = true,
            value = 1,
        },
        SK_CONJURATIONS = {
            allowed = true,
            value = 3,
        },
        SK_DODGING = {
            allowed = true,
            value = 1,
        },
        SK_EARTH_MAGIC = {
            allowed = true,
            value = -3,
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
            value = 1,
        },
        SK_HEXES = {
            allowed = true,
            value = -3,
        },
        SK_ICE_MAGIC = {
            allowed = true,
            value = -1,
        },
        SK_INVOCATIONS = {
            allowed = true,
            value = -1,
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
            value = 1,
        },
        SK_POISON_MAGIC = {
            allowed = true,
            value = 0,
        },
        SK_POLEARMS = {
            allowed = true,
            value = 1,
        },
        SK_RANGED_WEAPONS = {
            allowed = true,
            value = 1,
        },
        SK_SHIELDS = {
            allowed = true,
            value = 0,
        },
        SK_SHORT_BLADES = {
            allowed = true,
            value = 1,
        },
        SK_SPELLCASTING = {
            allowed = true,
            value = -1,
        },
        SK_STAVES = {
            allowed = true,
            value = 1,
        },
        SK_STEALTH = {
            allowed = true,
            value = 1,
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
            value = -2,
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
            id = "MUT_BEAK",
            amount = 1,
        },
        {
            level = 1,
            id = "MUT_TALONS",
            amount = 3,
        },
        {
            level = 5,
            id = "MUT_TENGU_FLIGHT",
            amount = 1,
        },
    },
    flags = {
        "SPF_NO_HAIR",
    },
    habitat = "HT_LAND",
    size = "SIZE_MEDIUM",
    undead_type = "US_ALIVE",
    recommended_jobs = {
        "JOB_BERSERKER",
        "JOB_HEDGE_WIZARD",
        "JOB_CONJURER",
        "JOB_SUMMONER",
        "JOB_FIRE_ELEMENTALIST",
        "JOB_AIR_ELEMENTALIST",
        "JOB_VENOM_MAGE",
    },
    recommended_weapons = {
        "SK_MACES_FLAILS",
        "SK_AXES",
        "SK_POLEARMS",
        "SK_LONG_BLADES",
        "SK_STAVES",
    },
    walking_verb = "Glid",
    -- Source: crawl-ref/source/dat/descript/species.txt
    description = "Tengu are bird-people who love to fight, both with weapons " ..
        "and spells. They are\nquite fragile, but they learn to fly " ..
        "swiftly later on.",
}

register.definition(categories.SPECIES, definition)

return definition
