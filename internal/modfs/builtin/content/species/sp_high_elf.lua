-- Generated from the pinned DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/util/species-gen/species-data-deprecated-species.txt

local categories = require("constants.catalog")

local definition = {
    id = "SP_HIGH_ELF",
    monster_id = "MONS_ELF",
    name = "High Elf",
    short_name = "HE",
    adjective = "Elven",
    genus = "Elf",
    selectable = false,
    xp = -1,
    hp = -1,
    mp_mod = 1,
    mr = 4,
    strength = 7,
    intelligence = 11,
    dexterity = 10,
    levelup_stat_frequency = 3,
    levelup_stats = {
        "int",
        "dex",
    },
    aptitudes = {
        SK_AIR_MAGIC = {
            allowed = true,
            value = 2,
        },
        SK_ARMOUR = {
            allowed = true,
            value = -1,
        },
        SK_AXES = {
            allowed = true,
            value = -2,
        },
        SK_CHARMS = {
            allowed = false,
            value = 0,
        },
        SK_CONJURATIONS = {
            allowed = true,
            value = 1,
        },
        SK_CROSSBOWS = {
            allowed = false,
            value = 0,
        },
        SK_DODGING = {
            allowed = true,
            value = 1,
        },
        SK_EARTH_MAGIC = {
            allowed = true,
            value = -2,
        },
        SK_EVOCATIONS = {
            allowed = true,
            value = 0,
        },
        SK_FIGHTING = {
            allowed = true,
            value = 0,
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
            value = 2,
        },
        SK_MACES_FLAILS = {
            allowed = true,
            value = -2,
        },
        SK_NECROMANCY = {
            allowed = true,
            value = -2,
        },
        SK_POISON_MAGIC = {
            allowed = true,
            value = -2,
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
            value = -1,
        },
        SK_SHORT_BLADES = {
            allowed = true,
            value = 2,
        },
        SK_SLINGS = {
            allowed = false,
            value = 0,
        },
        SK_SPELLCASTING = {
            allowed = true,
            value = 1,
        },
        SK_STABBING = {
            allowed = false,
            value = 0,
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
        SK_TRAPS = {
            allowed = false,
            value = 0,
        },
        SK_UNARMED_COMBAT = {
            allowed = true,
            value = -2,
        },
    },
    habitat = "HT_LAND",
    size = "SIZE_MEDIUM",
    undead_type = "US_ALIVE",
}

register.definition(categories.SPECIES, definition)

return definition
