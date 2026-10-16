-- Generated from the pinned DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/dat/species/troll.yaml

local categories = require("constants.catalog")
local groups = require("constants.menu_groups")

local definition = {
    id = "SP_TROLL",
    monster_id = "MONS_TROLL",
    name = "Troll",
    short_name = "Tr",
    adjective = "Trollish",
    selectable = true,
    difficulty = groups.SPECIES_SIMPLE,
    difficulty_priority = 40,
    xp = -1,
    hp = 3,
    mp_mod = -1,
    mr = 3,
    strength = 15,
    intelligence = 4,
    dexterity = 5,
    levelup_stat_frequency = 3,
    levelup_stats = {
        "str",
    },
    aptitudes = {
        SK_AIR_MAGIC = {
            allowed = true,
            value = -4,
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
            value = -3,
        },
        SK_DODGING = {
            allowed = true,
            value = -2,
        },
        SK_EARTH_MAGIC = {
            allowed = true,
            value = -1,
        },
        SK_EVOCATIONS = {
            allowed = true,
            value = -3,
        },
        SK_FIGHTING = {
            allowed = true,
            value = -2,
        },
        SK_FIRE_MAGIC = {
            allowed = true,
            value = -3,
        },
        SK_HEXES = {
            allowed = true,
            value = -4,
        },
        SK_ICE_MAGIC = {
            allowed = true,
            value = -3,
        },
        SK_INVOCATIONS = {
            allowed = true,
            value = -1,
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
            value = -2,
        },
        SK_POISON_MAGIC = {
            allowed = true,
            value = -3,
        },
        SK_POLEARMS = {
            allowed = true,
            value = -2,
        },
        SK_RANGED_WEAPONS = {
            allowed = true,
            value = -4,
        },
        SK_SHIELDS = {
            allowed = true,
            value = -1,
        },
        SK_SHORT_BLADES = {
            allowed = true,
            value = -2,
        },
        SK_SPELLCASTING = {
            allowed = true,
            value = -5,
        },
        SK_STAVES = {
            allowed = true,
            value = -2,
        },
        SK_STEALTH = {
            allowed = true,
            value = -5,
        },
        SK_SUMMONINGS = {
            allowed = true,
            value = -3,
        },
        SK_THROWING = {
            allowed = true,
            value = -1,
        },
        SK_TRANSLOCATIONS = {
            allowed = true,
            value = -3,
        },
        SK_TRANSMUTATIONS = {
            allowed = true,
            value = -3,
        },
        SK_UNARMED_COMBAT = {
            allowed = true,
            value = 0,
        },
    },
    mutations = {
        {
            level = 1,
            id = "MUT_CLAWS",
            amount = 3,
        },
        {
            level = 1,
            id = "MUT_REGENERATION",
            amount = 1,
        },
        {
            level = 1,
            id = "MUT_SHAGGY_FUR",
            amount = 1,
        },
        {
            level = 1,
            id = "MUT_TOUGH_SKIN",
            amount = 1,
        },
    },
    habitat = "HT_LAND",
    size = "SIZE_LARGE",
    undead_type = "US_ALIVE",
    recommended_jobs = {
        "JOB_FIGHTER",
        "JOB_GLADIATOR",
        "JOB_BERSERKER",
        "JOB_WARPER",
        "JOB_EARTH_ELEMENTALIST",
        "JOB_HEDGE_WIZARD",
    },
    recommended_weapons = {
        "SK_MACES_FLAILS",
        "SK_UNARMED_COMBAT",
    },
    -- Source: crawl-ref/source/dat/descript/species.txt
    description = "Trolls are monstrous creatures with powerful claws. They " ..
        "regenerate health\nrapidly.",
}

register.definition(categories.SPECIES, definition)

return definition
