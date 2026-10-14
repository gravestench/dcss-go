-- Generated from the pinned DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/dat/species/felid.yaml

register.species{
    id = "SP_FELID",
    monster_id = "MONS_FELID",
    source_path = "crawl-ref/source/dat/species/felid.yaml",
    name = "Felid",
    short_name = "Fe",
    adjective = "Feline",
    genus = "Cat",
    selectable = true,
    difficulty = "Advanced",
    difficulty_priority = 40,
    xp = -1,
    hp = -4,
    mp_mod = 1,
    mr = 6,
    strength = 4,
    intelligence = 9,
    dexterity = 11,
    levelup_stat_frequency = 5,
    levelup_stats = {
        "int",
        "dex",
    },
    aptitudes = {
        SK_AIR_MAGIC = {
            allowed = true,
            value = -1,
        },
        SK_ARMOUR = {
            allowed = false,
            value = 0,
        },
        SK_AXES = {
            allowed = false,
            value = 0,
        },
        SK_CONJURATIONS = {
            allowed = true,
            value = -1,
        },
        SK_DODGING = {
            allowed = true,
            value = 3,
        },
        SK_EARTH_MAGIC = {
            allowed = true,
            value = -1,
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
            value = -1,
        },
        SK_HEXES = {
            allowed = true,
            value = 4,
        },
        SK_ICE_MAGIC = {
            allowed = true,
            value = -1,
        },
        SK_INVOCATIONS = {
            allowed = true,
            value = 0,
        },
        SK_LONG_BLADES = {
            allowed = false,
            value = 0,
        },
        SK_MACES_FLAILS = {
            allowed = false,
            value = 0,
        },
        SK_NECROMANCY = {
            allowed = true,
            value = 0,
        },
        SK_POISON_MAGIC = {
            allowed = true,
            value = -1,
        },
        SK_POLEARMS = {
            allowed = false,
            value = 0,
        },
        SK_RANGED_WEAPONS = {
            allowed = false,
            value = 0,
        },
        SK_SHIELDS = {
            allowed = false,
            value = 0,
        },
        SK_SHORT_BLADES = {
            allowed = false,
            value = 0,
        },
        SK_SPELLCASTING = {
            allowed = true,
            value = -1,
        },
        SK_STAVES = {
            allowed = false,
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
            allowed = false,
            value = 0,
        },
        SK_TRANSLOCATIONS = {
            allowed = true,
            value = 4,
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
            id = "MUT_ACUTE_VISION",
            amount = 1,
        },
        {
            level = 1,
            id = "MUT_CLAWS",
            amount = 1,
        },
        {
            level = 1,
            id = "MUT_FANGS",
            amount = 3,
        },
        {
            level = 1,
            id = "MUT_FAST",
            amount = 1,
        },
        {
            level = 1,
            id = "MUT_MULTILIVED",
            amount = 1,
        },
        {
            level = 1,
            id = "MUT_NO_ARMOUR",
            amount = 1,
        },
        {
            level = 1,
            id = "MUT_NO_GRASPING",
            amount = 1,
        },
        {
            level = 1,
            id = "MUT_PAWS",
            amount = 1,
        },
        {
            level = 1,
            id = "MUT_SHAGGY_FUR",
            amount = 1,
        },
        {
            level = 6,
            id = "MUT_SHAGGY_FUR",
            amount = 1,
        },
        {
            level = 12,
            id = "MUT_SHAGGY_FUR",
            amount = 1,
        },
    },
    habitat = "HT_LAND",
    size = "SIZE_LITTLE",
    undead_type = "US_ALIVE",
    recommended_jobs = {
        "JOB_BERSERKER",
        "JOB_ENCHANTER",
        "JOB_TRANSMUTER",
        "JOB_ICE_ELEMENTALIST",
        "JOB_AIR_ELEMENTALIST",
        "JOB_CONJURER",
        "JOB_SUMMONER",
        "JOB_VENOM_MAGE",
    },
    recommended_weapons = {
        "SK_UNARMED_COMBAT",
    },
    altar_action = "sit before",
}
