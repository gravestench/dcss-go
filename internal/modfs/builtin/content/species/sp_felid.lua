-- Felid (SP_FELID) is a selectable species with HP modifier -4 and XP factor
-- -1.
-- Character creation projects its innate traits into player components; later
-- training consults aptitudes.

-- Source: crawl-ref/source/dat/species/felid.yaml

local categories = require("constants.catalog")
local groups = require("constants.menu_groups")

local definition = {
    id = "SP_FELID",
    monster_id = "MONS_FELID",
    name = "Felid",
    short_name = "Fe",
    adjective = "Feline",
    genus = "Cat",
    selectable = true,
    difficulty = groups.SPECIES_ADVANCED,
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
    -- Felid changes training costs through these aptitudes; current skill levels
    -- are player state.
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
    -- Source: crawl-ref/source/dat/descript/species.txt
    description = "Felids are many-lived cats possessing sentience. They are " ..
        "incapable of advanced\nitem manipulation or the use of armour " ..
        "or weapons.",
}

register.definition(categories.SPECIES, definition)

return definition
