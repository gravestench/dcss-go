-- Generated from the pinned DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/dat/species/mummy.yaml

local categories = require("constants.catalog")
local groups = require("constants.menu_groups")

local definition = {
    id = "SP_MUMMY",
    monster_id = "MONS_MUMMY",
    name = "Mummy",
    short_name = "Mu",
    selectable = true,
    difficulty = groups.SPECIES_ADVANCED,
    difficulty_priority = 20,
    xp = -1,
    hp = 0,
    mp_mod = 0,
    mr = 5,
    strength = 11,
    intelligence = 7,
    dexterity = 7,
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
            value = -2,
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
            value = -2,
        },
        SK_EARTH_MAGIC = {
            allowed = true,
            value = -2,
        },
        SK_EVOCATIONS = {
            allowed = true,
            value = -2,
        },
        SK_FIGHTING = {
            allowed = true,
            value = 0,
        },
        SK_FIRE_MAGIC = {
            allowed = true,
            value = -2,
        },
        SK_HEXES = {
            allowed = true,
            value = -1,
        },
        SK_ICE_MAGIC = {
            allowed = true,
            value = -2,
        },
        SK_INVOCATIONS = {
            allowed = true,
            value = -1,
        },
        SK_LONG_BLADES = {
            allowed = true,
            value = -2,
        },
        SK_MACES_FLAILS = {
            allowed = true,
            value = -2,
        },
        SK_NECROMANCY = {
            allowed = true,
            value = 0,
        },
        SK_POISON_MAGIC = {
            allowed = true,
            value = -2,
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
            value = -2,
        },
        SK_SHORT_BLADES = {
            allowed = true,
            value = -2,
        },
        SK_SPELLCASTING = {
            allowed = true,
            value = 2,
        },
        SK_STAVES = {
            allowed = true,
            value = -2,
        },
        SK_STEALTH = {
            allowed = true,
            value = -1,
        },
        SK_SUMMONINGS = {
            allowed = true,
            value = -2,
        },
        SK_THROWING = {
            allowed = true,
            value = -2,
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
            value = -2,
        },
    },
    mutations = {
        {
            level = 1,
            id = "MUT_COLD_RESISTANCE",
            amount = 1,
        },
        {
            level = 1,
            id = "MUT_HEAT_VULNERABILITY",
            amount = 1,
        },
        {
            level = 1,
            id = "MUT_NEGATIVE_ENERGY_RESISTANCE",
            amount = 3,
        },
        {
            level = 1,
            id = "MUT_NO_DRINK",
            amount = 1,
        },
        {
            level = 1,
            id = "MUT_TORMENT_RESISTANCE",
            amount = 2,
        },
        {
            level = 3,
            id = "MUT_NECRO_ENHANCER",
            amount = 1,
        },
        {
            level = 13,
            id = "MUT_NECRO_ENHANCER",
            amount = 1,
        },
    },
    habitat = "HT_LAND",
    size = "SIZE_MEDIUM",
    undead_type = "US_UNDEAD",
    recommended_jobs = {
        "JOB_CINDER_ACOLYTE",
        "JOB_HEDGE_WIZARD",
        "JOB_CONJURER",
        "JOB_NECROMANCER",
        "JOB_ICE_ELEMENTALIST",
        "JOB_SUMMONER",
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
    description = "Compelled to walk by an ancient curse, Mummies are adept at " ..
        "Necromancy but\nlearn other skills very slowly. They are " ..
        "unable to consume potions.",
}

register.definition(categories.SPECIES, definition)

return definition
