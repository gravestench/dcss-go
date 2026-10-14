-- Generated from the pinned DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/dat/species/kobold.yaml

register.species{
    id = "SP_KOBOLD",
    monster_id = "MONS_KOBOLD",
    source_path = "crawl-ref/source/dat/species/kobold.yaml",
    name = "Kobold",
    short_name = "Ko",
    selectable = true,
    difficulty = "Intermediate",
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
}
