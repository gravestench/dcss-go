-- Generated from the pinned DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/dat/species/deprecated-centaur.yaml

register.species{
    id = "SP_CENTAUR",
    monster_id = "MONS_CENTAUR",
    source_path = "crawl-ref/source/dat/species/deprecated-centaur.yaml",
    name = "Centaur",
    short_name = "Ce",
    selectable = false,
    xp = -1,
    hp = 1,
    mp_mod = 0,
    mr = 3,
    strength = 10,
    intelligence = 7,
    dexterity = 4,
    levelup_stat_frequency = 4,
    levelup_stats = {
        "str",
        "dex",
    },
    aptitudes = {
        SK_AIR_MAGIC = {
            allowed = true,
            value = -1,
        },
        SK_ARMOUR = {
            allowed = true,
            value = -3,
        },
        SK_AXES = {
            allowed = true,
            value = -1,
        },
        SK_CONJURATIONS = {
            allowed = true,
            value = -1,
        },
        SK_DODGING = {
            allowed = true,
            value = -3,
        },
        SK_EARTH_MAGIC = {
            allowed = true,
            value = -1,
        },
        SK_EVOCATIONS = {
            allowed = true,
            value = -1,
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
            value = -1,
        },
        SK_ICE_MAGIC = {
            allowed = true,
            value = -1,
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
            value = -1,
        },
        SK_POISON_MAGIC = {
            allowed = true,
            value = -2,
        },
        SK_POLEARMS = {
            allowed = true,
            value = -1,
        },
        SK_RANGED_WEAPONS = {
            allowed = true,
            value = 3,
        },
        SK_SHIELDS = {
            allowed = true,
            value = -3,
        },
        SK_SHORT_BLADES = {
            allowed = true,
            value = -1,
        },
        SK_SPELLCASTING = {
            allowed = true,
            value = -3,
        },
        SK_STAVES = {
            allowed = true,
            value = -1,
        },
        SK_STEALTH = {
            allowed = true,
            value = -4,
        },
        SK_SUMMONINGS = {
            allowed = true,
            value = -1,
        },
        SK_THROWING = {
            allowed = true,
            value = 1,
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
            value = 0,
        },
    },
    mutations = {
        {
            level = 1,
            id = "MUT_DEFORMED",
            amount = 1,
        },
        {
            level = 1,
            id = "MUT_FAST",
            amount = 2,
        },
        {
            level = 1,
            id = "MUT_HOOVES",
            amount = 3,
        },
        {
            level = 1,
            id = "MUT_TOUGH_SKIN",
            amount = 3,
        },
    },
    flags = {
        "SPF_BARDING",
        "SPF_SMALL_TORSO",
    },
    habitat = "HT_LAND",
    size = "SIZE_LARGE",
    undead_type = "US_ALIVE",
}
