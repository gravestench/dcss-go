-- Generated from the pinned DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/dat/species/deep-dwarf.yaml

register.species{
    id = "SP_DEEP_DWARF",
    monster_id = "MONS_DEEP_DWARF",
    source_path = "crawl-ref/source/dat/species/deep-dwarf.yaml",
    name = "Deep Dwarf",
    short_name = "DD",
    adjective = "Dwarven",
    genus = "Dwarf",
    selectable = false,
    xp = -1,
    hp = 2,
    mp_mod = 0,
    mr = 6,
    strength = 11,
    intelligence = 8,
    dexterity = 8,
    levelup_stat_frequency = 4,
    levelup_stats = {
        "str",
        "int",
    },
    aptitudes = {
        SK_AIR_MAGIC = {
            allowed = true,
            value = -3,
        },
        SK_ARMOUR = {
            allowed = true,
            value = 1,
        },
        SK_AXES = {
            allowed = true,
            value = 1,
        },
        SK_CONJURATIONS = {
            allowed = true,
            value = -1,
        },
        SK_DODGING = {
            allowed = true,
            value = 1,
        },
        SK_EARTH_MAGIC = {
            allowed = true,
            value = 3,
        },
        SK_EVOCATIONS = {
            allowed = true,
            value = 3,
        },
        SK_FIGHTING = {
            allowed = true,
            value = -1,
        },
        SK_FIRE_MAGIC = {
            allowed = true,
            value = -1,
        },
        SK_HEXES = {
            allowed = true,
            value = -2,
        },
        SK_ICE_MAGIC = {
            allowed = true,
            value = -1,
        },
        SK_INVOCATIONS = {
            allowed = true,
            value = 3,
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
            value = 1,
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
            value = 1,
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
            value = -2,
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
            value = -1,
        },
        SK_THROWING = {
            allowed = true,
            value = -1,
        },
        SK_TRANSLOCATIONS = {
            allowed = true,
            value = 1,
        },
        SK_TRANSMUTATIONS = {
            allowed = true,
            value = -1,
        },
        SK_UNARMED_COMBAT = {
            allowed = true,
            value = -1,
        },
    },
    mutations = {
        {
            level = 1,
            id = "MUT_NO_REGENERATION",
            amount = 1,
        },
        {
            level = 1,
            id = "MUT_PASSIVE_MAPPING",
            amount = 1,
        },
        {
            level = 9,
            id = "MUT_PASSIVE_MAPPING",
            amount = 1,
        },
        {
            level = 14,
            id = "MUT_NEGATIVE_ENERGY_RESISTANCE",
            amount = 1,
        },
        {
            level = 18,
            id = "MUT_PASSIVE_MAPPING",
            amount = 1,
        },
    },
    fake_mutations = {
        {
            long = "You are resistant to damage.",
            short = "damage resistance",
        },
        {
            long = "You can heal yourself by infusing magical energy.",
            short = "heal wounds",
        },
    },
    habitat = "HT_LAND",
    size = "SIZE_MEDIUM",
    undead_type = "US_ALIVE",
}
