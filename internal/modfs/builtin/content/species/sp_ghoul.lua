-- Generated from the pinned DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/dat/species/ghoul.yaml

register.species{
    id = "SP_GHOUL",
    monster_id = "MONS_GHOUL",
    source_path = "crawl-ref/source/dat/species/ghoul.yaml",
    name = "Ghoul",
    short_name = "Gh",
    adjective = "Ghoulish",
    selectable = true,
    difficulty = "Simple",
    difficulty_priority = 30,
    xp = 0,
    hp = 1,
    mp_mod = -1,
    mr = 3,
    strength = 11,
    intelligence = 3,
    dexterity = 4,
    levelup_stat_frequency = 5,
    levelup_stats = {
        "str",
    },
    aptitudes = {
        SK_AIR_MAGIC = {
            allowed = true,
            value = -2,
        },
        SK_ARMOUR = {
            allowed = true,
            value = -1,
        },
        SK_AXES = {
            allowed = true,
            value = -1,
        },
        SK_CONJURATIONS = {
            allowed = true,
            value = -2,
        },
        SK_DODGING = {
            allowed = true,
            value = -1,
        },
        SK_EARTH_MAGIC = {
            allowed = true,
            value = 1,
        },
        SK_EVOCATIONS = {
            allowed = true,
            value = -1,
        },
        SK_FIGHTING = {
            allowed = true,
            value = 1,
        },
        SK_FIRE_MAGIC = {
            allowed = true,
            value = -2,
        },
        SK_HEXES = {
            allowed = true,
            value = -2,
        },
        SK_ICE_MAGIC = {
            allowed = true,
            value = 1,
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
            value = -2,
        },
        SK_STAVES = {
            allowed = true,
            value = -1,
        },
        SK_STEALTH = {
            allowed = true,
            value = 2,
        },
        SK_SUMMONINGS = {
            allowed = true,
            value = -1,
        },
        SK_THROWING = {
            allowed = true,
            value = -1,
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
            value = 1,
        },
    },
    mutations = {
        {
            level = 1,
            id = "MUT_CLAWS",
            amount = 1,
        },
        {
            level = 1,
            id = "MUT_COLD_RESISTANCE",
            amount = 1,
        },
        {
            level = 1,
            id = "MUT_DEVOUR_ON_KILL",
            amount = 1,
        },
        {
            level = 1,
            id = "MUT_INHIBITED_REGENERATION",
            amount = 1,
        },
        {
            level = 1,
            id = "MUT_NEGATIVE_ENERGY_RESISTANCE",
            amount = 3,
        },
        {
            level = 1,
            id = "MUT_TORMENT_RESISTANCE",
            amount = 2,
        },
    },
    flags = {
        "SPF_NO_HAIR",
    },
    habitat = "HT_LAND",
    size = "SIZE_MEDIUM",
    undead_type = "US_UNDEAD",
    recommended_jobs = {
        "JOB_WARPER",
        "JOB_GLADIATOR",
        "JOB_MONK",
        "JOB_NECROMANCER",
        "JOB_ICE_ELEMENTALIST",
        "JOB_EARTH_ELEMENTALIST",
    },
    recommended_weapons = {
        "SK_UNARMED_COMBAT",
    },
}
