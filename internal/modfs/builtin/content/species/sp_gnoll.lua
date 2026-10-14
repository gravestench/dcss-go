-- Generated from the pinned DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/dat/species/gnoll.yaml

register.species{
    id = "SP_GNOLL",
    monster_id = "MONS_GNOLL",
    source_path = "crawl-ref/source/dat/species/gnoll.yaml",
    name = "Gnoll",
    short_name = "Gn",
    selectable = true,
    difficulty = "Simple",
    difficulty_priority = 10,
    xp = 0,
    hp = 0,
    mp_mod = 0,
    mr = 3,
    strength = 7,
    intelligence = 7,
    dexterity = 7,
    levelup_stat_frequency = 4,
    levelup_stats = {
        "str",
        "int",
        "dex",
    },
    aptitudes = {
        SK_AIR_MAGIC = {
            allowed = true,
            value = 6,
        },
        SK_ARMOUR = {
            allowed = true,
            value = 8,
        },
        SK_AXES = {
            allowed = true,
            value = 8,
        },
        SK_CONJURATIONS = {
            allowed = true,
            value = 6,
        },
        SK_DODGING = {
            allowed = true,
            value = 8,
        },
        SK_EARTH_MAGIC = {
            allowed = true,
            value = 6,
        },
        SK_EVOCATIONS = {
            allowed = true,
            value = 8,
        },
        SK_FIGHTING = {
            allowed = true,
            value = 8,
        },
        SK_FIRE_MAGIC = {
            allowed = true,
            value = 6,
        },
        SK_HEXES = {
            allowed = true,
            value = 6,
        },
        SK_ICE_MAGIC = {
            allowed = true,
            value = 6,
        },
        SK_INVOCATIONS = {
            allowed = true,
            value = 9,
        },
        SK_LONG_BLADES = {
            allowed = true,
            value = 8,
        },
        SK_MACES_FLAILS = {
            allowed = true,
            value = 8,
        },
        SK_NECROMANCY = {
            allowed = true,
            value = 6,
        },
        SK_POISON_MAGIC = {
            allowed = true,
            value = 6,
        },
        SK_POLEARMS = {
            allowed = true,
            value = 8,
        },
        SK_RANGED_WEAPONS = {
            allowed = true,
            value = 8,
        },
        SK_SHIELDS = {
            allowed = true,
            value = 8,
        },
        SK_SHORT_BLADES = {
            allowed = true,
            value = 8,
        },
        SK_SPELLCASTING = {
            allowed = true,
            value = 8,
        },
        SK_STAVES = {
            allowed = true,
            value = 8,
        },
        SK_STEALTH = {
            allowed = true,
            value = 8,
        },
        SK_SUMMONINGS = {
            allowed = true,
            value = 6,
        },
        SK_THROWING = {
            allowed = true,
            value = 8,
        },
        SK_TRANSLOCATIONS = {
            allowed = true,
            value = 6,
        },
        SK_TRANSMUTATIONS = {
            allowed = true,
            value = 6,
        },
        SK_UNARMED_COMBAT = {
            allowed = true,
            value = 8,
        },
    },
    mutations = {
        {
            level = 1,
            id = "MUT_DISTRIBUTED_TRAINING",
            amount = 1,
        },
        {
            level = 1,
            id = "MUT_FANGS",
            amount = 1,
        },
        {
            level = 1,
            id = "MUT_STRONG_NOSE",
            amount = 1,
        },
    },
    habitat = "HT_LAND",
    size = "SIZE_MEDIUM",
    undead_type = "US_ALIVE",
    recommended_jobs = {
        "JOB_CINDER_ACOLYTE",
        "JOB_WARPER",
        "JOB_ARCANE_MARKSMAN",
        "JOB_TRANSMUTER",
        "JOB_WANDERER",
    },
    recommended_weapons = {
        "SK_LONG_BLADES",
        "SK_AXES",
        "SK_MACES_FLAILS",
        "SK_POLEARMS",
        "SK_STAVES",
        "SK_RANGED_WEAPONS",
    },
}
