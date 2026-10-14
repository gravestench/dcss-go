-- Generated from the pinned DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/dat/species/gargoyle.yaml

register.species{
    id = "SP_GARGOYLE",
    monster_id = "MONS_GARGOYLE",
    source_path = "crawl-ref/source/dat/species/gargoyle.yaml",
    name = "Gargoyle",
    short_name = "Gr",
    selectable = true,
    difficulty = "Simple",
    difficulty_priority = 70,
    xp = 0,
    hp = -2,
    mp_mod = 0,
    mr = 3,
    strength = 11,
    intelligence = 8,
    dexterity = 5,
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
            value = -1,
        },
        SK_CONJURATIONS = {
            allowed = true,
            value = 1,
        },
        SK_DODGING = {
            allowed = true,
            value = -2,
        },
        SK_EARTH_MAGIC = {
            allowed = true,
            value = 2,
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
            value = 0,
        },
        SK_HEXES = {
            allowed = true,
            value = -1,
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
            value = -1,
        },
        SK_MACES_FLAILS = {
            allowed = true,
            value = 0,
        },
        SK_NECROMANCY = {
            allowed = true,
            value = -2,
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
            value = 0,
        },
        SK_SHIELDS = {
            allowed = true,
            value = 1,
        },
        SK_SHORT_BLADES = {
            allowed = true,
            value = -1,
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
            value = -2,
        },
        SK_UNARMED_COMBAT = {
            allowed = true,
            value = 0,
        },
    },
    mutations = {
        {
            level = 1,
            id = "MUT_NEGATIVE_ENERGY_RESISTANCE",
            amount = 1,
        },
        {
            level = 1,
            id = "MUT_PETRIFICATION_RESISTANCE",
            amount = 1,
        },
        {
            level = 1,
            id = "MUT_SHOCK_RESISTANCE",
            amount = 1,
        },
        {
            level = 1,
            id = "MUT_TORMENT_RESISTANCE",
            amount = 1,
        },
        {
            level = 14,
            id = "MUT_BIG_WINGS",
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
    flags = {
        "SPF_NO_HAIR",
    },
    habitat = "HT_LAND",
    size = "SIZE_MEDIUM",
    undead_type = "US_ALIVE",
    recommended_jobs = {
        "JOB_FIGHTER",
        "JOB_GLADIATOR",
        "JOB_MONK",
        "JOB_BERSERKER",
        "JOB_FIRE_ELEMENTALIST",
        "JOB_ICE_ELEMENTALIST",
        "JOB_EARTH_ELEMENTALIST",
        "JOB_VENOM_MAGE",
    },
    recommended_weapons = {
        "SK_MACES_FLAILS",
        "SK_STAVES",
    },
}
