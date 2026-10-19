-- Vampire (SP_VAMPIRE) is a selectable species with HP modifier 0 and XP
-- factor -1.
-- Character creation projects its innate traits into player components; later
-- training consults aptitudes.

-- Source: crawl-ref/source/dat/species/vampire.yaml

local categories = require("constants.catalog")
local groups = require("constants.menu_groups")

local definition = {
    id = "SP_VAMPIRE",
    monster_id = "MONS_VAMPIRE",
    name = "Vampire",
    short_name = "Vp",
    adjective = "Vampiric",
    selectable = true,
    difficulty = groups.SPECIES_ADVANCED,
    difficulty_priority = 90,
    xp = -1,
    hp = 0,
    mp_mod = 0,
    mr = 4,
    strength = 7,
    intelligence = 10,
    dexterity = 9,
    levelup_stat_frequency = 5,
    levelup_stats = {
        "int",
        "dex",
    },
    -- Vampire changes training costs through these aptitudes; current skill levels
    -- are player state.
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
            value = -1,
        },
        SK_CONJURATIONS = {
            allowed = true,
            value = -3,
        },
        SK_DODGING = {
            allowed = true,
            value = 1,
        },
        SK_EARTH_MAGIC = {
            allowed = true,
            value = 0,
        },
        SK_EVOCATIONS = {
            allowed = true,
            value = -1,
        },
        SK_FIGHTING = {
            allowed = true,
            value = -1,
        },
        SK_FIRE_MAGIC = {
            allowed = true,
            value = -2,
        },
        SK_HEXES = {
            allowed = true,
            value = 4,
        },
        SK_ICE_MAGIC = {
            allowed = true,
            value = 0,
        },
        SK_INVOCATIONS = {
            allowed = true,
            value = -1,
        },
        SK_LONG_BLADES = {
            allowed = true,
            value = 0,
        },
        SK_MACES_FLAILS = {
            allowed = true,
            value = -2,
        },
        SK_NECROMANCY = {
            allowed = true,
            value = 1,
        },
        SK_POISON_MAGIC = {
            allowed = true,
            value = -1,
        },
        SK_POLEARMS = {
            allowed = true,
            value = -1,
        },
        SK_RANGED_WEAPONS = {
            allowed = true,
            value = -2,
        },
        SK_SHIELDS = {
            allowed = true,
            value = -1,
        },
        SK_SHORT_BLADES = {
            allowed = true,
            value = 1,
        },
        SK_SPELLCASTING = {
            allowed = true,
            value = -1,
        },
        SK_STAVES = {
            allowed = true,
            value = -2,
        },
        SK_STEALTH = {
            allowed = true,
            value = 5,
        },
        SK_SUMMONINGS = {
            allowed = true,
            value = 0,
        },
        SK_THROWING = {
            allowed = true,
            value = -2,
        },
        SK_TRANSLOCATIONS = {
            allowed = true,
            value = -2,
        },
        SK_TRANSMUTATIONS = {
            allowed = true,
            value = 1,
        },
        SK_UNARMED_COMBAT = {
            allowed = true,
            value = 1,
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
            id = "MUT_FANGS",
            amount = 3,
        },
        {
            level = 1,
            id = "MUT_VAMPIRISM",
            amount = 1,
        },
        {
            level = 3,
            id = "MUT_VAMPIRISM",
            amount = 1,
        },
    },
    habitat = "HT_LAND",
    size = "SIZE_MEDIUM",
    undead_type = "US_SEMI_UNDEAD",
    recommended_jobs = {
        "JOB_GLADIATOR",
        "JOB_BRIGAND",
        "JOB_ENCHANTER",
        "JOB_NECROMANCER",
        "JOB_EARTH_ELEMENTALIST",
        "JOB_ICE_ELEMENTALIST",
    },
    recommended_weapons = {
        "SK_SHORT_BLADES",
        "SK_AXES",
        "SK_LONG_BLADES",
    },
    -- Source: crawl-ref/source/dat/descript/species.txt
    description = "Shifting between the states of life and undeath at will, " ..
        "Vampires are\naccomplished stabbers and casters.",
}

register.definition(categories.SPECIES, definition)

return definition
