-- Gargoyle (SP_GARGOYLE) is a selectable species with HP modifier -2 and XP
-- factor 0.
-- Character creation projects its innate traits into player components; later
-- training consults aptitudes.

-- Source: crawl-ref/source/dat/species/gargoyle.yaml

local categories = require("constants.catalog")
local groups = require("constants.menu_groups")

local definition = {
    id = "SP_GARGOYLE",
    monster_id = "MONS_GARGOYLE",
    name = "Gargoyle",
    short_name = "Gr",
    selectable = true,
    difficulty = groups.SPECIES_SIMPLE,
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
    -- Gargoyle changes training costs through these aptitudes; current skill
    -- levels are player state.
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
    -- Source: crawl-ref/source/dat/descript/species.txt
    description = "Made of living stone, Gargoyles have a preternatural " ..
        "affinity for the earth.\nThey have low health, but their " ..
        "stone bodies are incredibly tough.",
}

register.definition(categories.SPECIES, definition)

return definition
