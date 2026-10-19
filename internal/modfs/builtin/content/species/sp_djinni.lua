-- Djinni (SP_DJINNI) is a selectable species with HP modifier -1 and XP
-- factor 1.
-- Character creation projects its innate traits into player components; later
-- training consults aptitudes.

-- Source: crawl-ref/source/dat/species/djinni.yaml

local categories = require("constants.catalog")
local groups = require("constants.menu_groups")

local definition = {
    id = "SP_DJINNI",
    monster_id = "MONS_DJINNI",
    name = "Djinni",
    short_name = "Dj",
    selectable = true,
    difficulty = groups.SPECIES_INTERMEDIATE,
    difficulty_priority = 70,
    xp = 1,
    hp = -1,
    mp_mod = 0,
    mr = 4,
    strength = 7,
    intelligence = 9,
    dexterity = 8,
    levelup_stat_frequency = 4,
    levelup_stats = {
        "dex",
        "int",
    },
    -- Djinni changes training costs through these aptitudes; current skill levels
    -- are player state.
    aptitudes = {
        SK_AIR_MAGIC = {
            allowed = false,
            value = 0,
        },
        SK_ARMOUR = {
            allowed = true,
            value = 0,
        },
        SK_AXES = {
            allowed = true,
            value = -2,
        },
        SK_CONJURATIONS = {
            allowed = false,
            value = 0,
        },
        SK_DODGING = {
            allowed = true,
            value = 1,
        },
        SK_EARTH_MAGIC = {
            allowed = false,
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
            allowed = false,
            value = 0,
        },
        SK_HEXES = {
            allowed = false,
            value = 0,
        },
        SK_ICE_MAGIC = {
            allowed = false,
            value = 0,
        },
        SK_INVOCATIONS = {
            allowed = true,
            value = 0,
        },
        SK_LONG_BLADES = {
            allowed = true,
            value = -1,
        },
        SK_MACES_FLAILS = {
            allowed = true,
            value = -2,
        },
        SK_NECROMANCY = {
            allowed = false,
            value = 0,
        },
        SK_POISON_MAGIC = {
            allowed = false,
            value = 0,
        },
        SK_POLEARMS = {
            allowed = true,
            value = -2,
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
            value = -1,
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
            allowed = false,
            value = 0,
        },
        SK_THROWING = {
            allowed = true,
            value = -2,
        },
        SK_TRANSLOCATIONS = {
            allowed = false,
            value = 0,
        },
        SK_TRANSMUTATIONS = {
            allowed = false,
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
            id = "MUT_COLD_VULNERABILITY",
            amount = 1,
        },
        {
            level = 1,
            id = "MUT_FLAT_HP",
            amount = 1,
        },
        {
            level = 1,
            id = "MUT_FLOAT",
            amount = 1,
        },
        {
            level = 1,
            id = "MUT_HEAT_RESISTANCE",
            amount = 2,
        },
        {
            level = 1,
            id = "MUT_HP_CASTING",
            amount = 1,
        },
        {
            level = 1,
            id = "MUT_INNATE_CASTER",
            amount = 1,
        },
    },
    fake_mutations = {
        {
            long = "You are immune to sickness and miasma.",
        },
        {
            short = "sickness immunity",
        },
    },
    habitat = "HT_LAND",
    size = "SIZE_MEDIUM",
    undead_type = "US_ALIVE",
    recommended_jobs = {
        "JOB_GLADIATOR",
        "JOB_TRANSMUTER",
        "JOB_HEDGE_WIZARD",
        "JOB_FIRE_ELEMENTALIST",
        "JOB_ICE_ELEMENTALIST",
    },
    recommended_weapons = {
        "SK_SHORT_BLADES",
        "SK_LONG_BLADES",
    },
    -- Source: crawl-ref/source/dat/descript/species.txt
    description = "Djinn are ever-burning spirits. They learn spells innately, " ..
        "without books, and\ncast by drawing down their own fires.",
}

register.definition(categories.SPECIES, definition)

return definition
