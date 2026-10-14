-- Generated from the pinned DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/dat/species/meteoran.yaml

register.species{
    id = "SP_METEORAN",
    monster_id = "MONS_METEORAN",
    source_path = "crawl-ref/source/dat/species/meteoran.yaml",
    name = "Meteoran",
    short_name = "Me",
    adjective = "Meteoric",
    selectable = true,
    difficulty = "Advanced",
    difficulty_priority = 30,
    xp = 2,
    hp = 1,
    mp_mod = 1,
    mr = 5,
    strength = 9,
    intelligence = 9,
    dexterity = 9,
    levelup_stat_frequency = 3,
    levelup_stats = {
        "str",
        "int",
        "dex",
    },
    aptitudes = {
        SK_AIR_MAGIC = {
            allowed = true,
            value = 2,
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
            value = 2,
        },
        SK_DODGING = {
            allowed = true,
            value = 2,
        },
        SK_EARTH_MAGIC = {
            allowed = true,
            value = 2,
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
            value = 2,
        },
        SK_HEXES = {
            allowed = true,
            value = 2,
        },
        SK_ICE_MAGIC = {
            allowed = true,
            value = 1,
        },
        SK_INVOCATIONS = {
            allowed = true,
            value = 3,
        },
        SK_LONG_BLADES = {
            allowed = true,
            value = 2,
        },
        SK_MACES_FLAILS = {
            allowed = true,
            value = 3,
        },
        SK_NECROMANCY = {
            allowed = true,
            value = 1,
        },
        SK_POISON_MAGIC = {
            allowed = true,
            value = 2,
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
            value = 2,
        },
        SK_STAVES = {
            allowed = true,
            value = 2,
        },
        SK_STEALTH = {
            allowed = true,
            value = -2,
        },
        SK_SUMMONINGS = {
            allowed = true,
            value = 2,
        },
        SK_THROWING = {
            allowed = true,
            value = 2,
        },
        SK_TRANSLOCATIONS = {
            allowed = true,
            value = 2,
        },
        SK_TRANSMUTATIONS = {
            allowed = true,
            value = 2,
        },
        SK_UNARMED_COMBAT = {
            allowed = true,
            value = 2,
        },
    },
    mutations = {
        {
            level = 1,
            id = "MUT_EXPLORE_REGEN",
            amount = 1,
        },
        {
            level = 1,
            id = "MUT_GLOWING",
            amount = 1,
        },
        {
            level = 1,
            id = "MUT_PASSIVE_MAPPING",
            amount = 1,
        },
        {
            level = 1,
            id = "MUT_SHORT_LIFESPAN",
            amount = 1,
        },
        {
            level = 9,
            id = "MUT_PASSIVE_MAPPING",
            amount = 1,
        },
        {
            level = 18,
            id = "MUT_PASSIVE_MAPPING",
            amount = 1,
        },
    },
    habitat = "HT_LAND",
    size = "SIZE_MEDIUM",
    undead_type = "US_ALIVE",
    recommended_jobs = {
        "JOB_FIGHTER",
        "JOB_WANDERER",
        "JOB_CINDER_ACOLYTE",
        "JOB_TRANSMUTER",
        "JOB_EARTH_ELEMENTALIST",
    },
    recommended_weapons = {
        "SK_MACES_FLAILS",
        "SK_POLEARMS",
        "SK_AXES",
        "SK_STAVES",
        "SK_LONG_BLADES",
    },
}
