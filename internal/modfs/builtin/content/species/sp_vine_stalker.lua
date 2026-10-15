-- Generated from the pinned DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/dat/species/vine-stalker.yaml

local categories = require("constants.catalog")

local definition = {
    id = "SP_VINE_STALKER",
    monster_id = "MONS_VINE_STALKER",
    name = "Vine Stalker",
    short_name = "VS",
    selectable = true,
    difficulty = "Advanced",
    difficulty_priority = 100,
    xp = 0,
    hp = -3,
    mp_mod = 1,
    mr = 5,
    strength = 10,
    intelligence = 8,
    dexterity = 9,
    levelup_stat_frequency = 4,
    levelup_stats = {
        "str",
        "dex",
    },
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
            value = -1,
        },
        SK_CONJURATIONS = {
            allowed = true,
            value = 0,
        },
        SK_DODGING = {
            allowed = true,
            value = -2,
        },
        SK_EARTH_MAGIC = {
            allowed = true,
            value = 0,
        },
        SK_EVOCATIONS = {
            allowed = true,
            value = -1,
        },
        SK_FIGHTING = {
            allowed = true,
            value = -1,
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
            value = 0,
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
            value = 0,
        },
        SK_POISON_MAGIC = {
            allowed = true,
            value = 0,
        },
        SK_POLEARMS = {
            allowed = true,
            value = -1,
        },
        SK_RANGED_WEAPONS = {
            allowed = true,
            value = -1,
        },
        SK_SHIELDS = {
            allowed = true,
            value = -1,
        },
        SK_SHORT_BLADES = {
            allowed = true,
            value = -1,
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
            value = 3,
        },
        SK_SUMMONINGS = {
            allowed = true,
            value = 0,
        },
        SK_THROWING = {
            allowed = true,
            value = -1,
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
            id = "MUT_ANTIMAGIC_BITE",
            amount = 1,
        },
        {
            level = 1,
            id = "MUT_FANGS",
            amount = 2,
        },
        {
            level = 1,
            id = "MUT_MANA_SHIELD",
            amount = 1,
        },
        {
            level = 1,
            id = "MUT_NO_POTION_HEAL",
            amount = 2,
        },
        {
            level = 4,
            id = "MUT_REGENERATION",
            amount = 1,
        },
        {
            level = 8,
            id = "MUT_FANGS",
            amount = 1,
        },
    },
    habitat = "HT_LAND",
    size = "SIZE_MEDIUM",
    undead_type = "US_ALIVE",
    recommended_jobs = {
        "JOB_FIGHTER",
        "JOB_BRIGAND",
        "JOB_BERSERKER",
        "JOB_ENCHANTER",
        "JOB_CONJURER",
        "JOB_NECROMANCER",
        "JOB_ICE_ELEMENTALIST",
    },
    recommended_weapons = {
        "SK_MACES_FLAILS",
        "SK_AXES",
        "SK_POLEARMS",
        "SK_LONG_BLADES",
        "SK_STAVES",
    },
    walking_verb = "Stalk",
}

register.definition(categories.SPECIES, definition)

return definition
