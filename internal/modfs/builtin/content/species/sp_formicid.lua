-- Generated from the pinned DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/dat/species/formicid.yaml

local categories = require("constants.catalog")
local groups = require("constants.menu_groups")

local definition = {
    id = "SP_FORMICID",
    monster_id = "MONS_FORMICID",
    name = "Formicid",
    short_name = "Fo",
    genus = "Ant",
    selectable = true,
    difficulty = groups.SPECIES_ADVANCED,
    difficulty_priority = 70,
    xp = 1,
    hp = 0,
    mp_mod = 0,
    mr = 4,
    strength = 12,
    intelligence = 7,
    dexterity = 9,
    levelup_stat_frequency = 4,
    levelup_stats = {
        "str",
        "int",
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
            value = 2,
        },
        SK_EVOCATIONS = {
            allowed = true,
            value = 1,
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
            value = 2,
        },
        SK_ICE_MAGIC = {
            allowed = true,
            value = 0,
        },
        SK_INVOCATIONS = {
            allowed = true,
            value = 2,
        },
        SK_LONG_BLADES = {
            allowed = true,
            value = 0,
        },
        SK_MACES_FLAILS = {
            allowed = true,
            value = 0,
        },
        SK_NECROMANCY = {
            allowed = true,
            value = 0,
        },
        SK_POISON_MAGIC = {
            allowed = true,
            value = 3,
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
            value = 3,
        },
        SK_SHORT_BLADES = {
            allowed = true,
            value = 0,
        },
        SK_SPELLCASTING = {
            allowed = true,
            value = 0,
        },
        SK_STAVES = {
            allowed = true,
            value = 0,
        },
        SK_STEALTH = {
            allowed = true,
            value = 3,
        },
        SK_SUMMONINGS = {
            allowed = true,
            value = 0,
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
            value = 1,
        },
        SK_UNARMED_COMBAT = {
            allowed = true,
            value = 0,
        },
    },
    mutations = {
        {
            level = 1,
            id = "MUT_ANTENNAE",
            amount = 3,
        },
        {
            level = 1,
            id = "MUT_QUADRUMANOUS",
            amount = 1,
        },
    },
    fake_mutations = {
        {
            long = "You cannot be hasted, slowed, berserked, paralysed or teleported.",
            short = "permanent stasis",
        },
        {
            long = "You can dig through walls and to a lower floor.",
            short = "dig shafts and tunnels",
        },
    },
    flags = {
        "SPF_NO_BONES",
    },
    habitat = "HT_LAND",
    size = "SIZE_MEDIUM",
    undead_type = "US_ALIVE",
    recommended_jobs = {
        "JOB_FIGHTER",
        "JOB_HUNTER",
        "JOB_ABYSSAL_KNIGHT",
        "JOB_ARCANE_MARKSMAN",
        "JOB_EARTH_ELEMENTALIST",
        "JOB_VENOM_MAGE",
    },
    recommended_weapons = {
        "SK_MACES_FLAILS",
        "SK_AXES",
        "SK_POLEARMS",
        "SK_STAVES",
    },
    -- Source: crawl-ref/source/dat/descript/species.txt
    description = "Formicids are humanoid ants adept at digging. Their limbs " ..
        "are exceptionally\nstrong and they live in a state of " ..
        "permanent stasis.",
}

register.definition(categories.SPECIES, definition)

return definition
