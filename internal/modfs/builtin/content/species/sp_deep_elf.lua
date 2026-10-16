-- Generated from the pinned DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/dat/species/deep-elf.yaml

local categories = require("constants.catalog")
local groups = require("constants.menu_groups")

local definition = {
    id = "SP_DEEP_ELF",
    monster_id = "MONS_ELF",
    name = "Deep Elf",
    short_name = "DE",
    adjective = "Elven",
    genus = "Elf",
    selectable = true,
    difficulty = groups.SPECIES_INTERMEDIATE,
    difficulty_priority = 40,
    xp = -1,
    hp = -2,
    mp_mod = 2,
    mr = 4,
    strength = 5,
    intelligence = 12,
    dexterity = 10,
    levelup_stat_frequency = 4,
    levelup_stats = {
        "int",
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
            value = 1,
        },
        SK_DODGING = {
            allowed = true,
            value = 2,
        },
        SK_EARTH_MAGIC = {
            allowed = true,
            value = 1,
        },
        SK_EVOCATIONS = {
            allowed = true,
            value = 1,
        },
        SK_FIGHTING = {
            allowed = true,
            value = -2,
        },
        SK_FIRE_MAGIC = {
            allowed = true,
            value = 1,
        },
        SK_HEXES = {
            allowed = true,
            value = 3,
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
            value = -3,
        },
        SK_NECROMANCY = {
            allowed = true,
            value = 2,
        },
        SK_POISON_MAGIC = {
            allowed = true,
            value = 1,
        },
        SK_POLEARMS = {
            allowed = true,
            value = -3,
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
            value = 0,
        },
        SK_SPELLCASTING = {
            allowed = true,
            value = 3,
        },
        SK_STAVES = {
            allowed = true,
            value = 0,
        },
        SK_STEALTH = {
            allowed = true,
            value = 3,
        },
        SK_SUMMONINGS = {
            allowed = true,
            value = 1,
        },
        SK_THROWING = {
            allowed = true,
            value = 0,
        },
        SK_TRANSLOCATIONS = {
            allowed = true,
            value = 1,
        },
        SK_TRANSMUTATIONS = {
            allowed = true,
            value = 1,
        },
        SK_UNARMED_COMBAT = {
            allowed = true,
            value = -2,
        },
    },
    habitat = "HT_LAND",
    size = "SIZE_MEDIUM",
    undead_type = "US_ALIVE",
    recommended_jobs = {
        "JOB_HEDGE_WIZARD",
        "JOB_CONJURER",
        "JOB_SUMMONER",
        "JOB_NECROMANCER",
        "JOB_FIRE_ELEMENTALIST",
        "JOB_ICE_ELEMENTALIST",
        "JOB_AIR_ELEMENTALIST",
        "JOB_EARTH_ELEMENTALIST",
        "JOB_VENOM_MAGE",
    },
    recommended_weapons = {
        "SK_SHORT_BLADES",
        "SK_STAVES",
    },
    -- Source: crawl-ref/source/dat/descript/species.txt
    description = "Deep Elves have a strong affinity for all kinds of magic, " ..
        "but are very fragile.",
}

register.definition(categories.SPECIES, definition)

return definition
