-- Generated from the pinned DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/dat/species/octopode.yaml

local categories = require("constants.catalog")

local definition = {
    id = "SP_OCTOPODE",
    monster_id = "MONS_OCTOPODE",
    name = "Octopode",
    short_name = "Op",
    adjective = "Octopoid",
    genus = "Octopus",
    selectable = true,
    difficulty = "Advanced",
    difficulty_priority = 50,
    xp = 0,
    hp = -1,
    mp_mod = 0,
    mr = 3,
    strength = 7,
    intelligence = 10,
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
            value = 0,
        },
        SK_ARMOUR = {
            allowed = false,
            value = 0,
        },
        SK_AXES = {
            allowed = true,
            value = 0,
        },
        SK_CONJURATIONS = {
            allowed = true,
            value = 0,
        },
        SK_DODGING = {
            allowed = true,
            value = 0,
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
            value = 0,
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
            value = 2,
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
            value = 0,
        },
        SK_SHORT_BLADES = {
            allowed = true,
            value = 0,
        },
        SK_SPELLCASTING = {
            allowed = true,
            value = -1,
        },
        SK_STAVES = {
            allowed = true,
            value = 0,
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
            value = 0,
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
            id = "MUT_CAMOUFLAGE",
            amount = 1,
        },
        {
            level = 1,
            id = "MUT_GELATINOUS_BODY",
            amount = 1,
        },
        {
            level = 1,
            id = "MUT_NIMBLE_SWIMMER",
            amount = 1,
        },
        {
            level = 1,
            id = "MUT_TENTACLE_ARMS",
            amount = 1,
        },
    },
    fake_mutations = {
        {
            long = "You cannot wear most types of armour.",
            short = "almost no armour",
        },
    },
    flags = {
        "SPF_NO_BONES",
        "SPF_NO_HAIR",
    },
    habitat = "HT_WATER",
    size = "SIZE_MEDIUM",
    undead_type = "US_ALIVE",
    recommended_jobs = {
        "JOB_TRANSMUTER",
        "JOB_HEDGE_WIZARD",
        "JOB_CONJURER",
        "JOB_BRIGAND",
        "JOB_FIRE_ELEMENTALIST",
        "JOB_EARTH_ELEMENTALIST",
        "JOB_VENOM_MAGE",
    },
    recommended_weapons = {
        "SK_LONG_BLADES",
        "SK_AXES",
        "SK_MACES_FLAILS",
        "SK_POLEARMS",
        "SK_STAVES",
        "SK_RANGED_WEAPONS",
    },
    walking_verb = "Wriggl",
    altar_action = "curl up in front of",
}

register.definition(categories.SPECIES, definition)

return definition
