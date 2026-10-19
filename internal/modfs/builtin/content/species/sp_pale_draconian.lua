-- Pale Draconian (SP_PALE_DRACONIAN) is a catalogued species with HP modifier
-- 1 and XP factor -1.
-- Its traits and aptitudes remain catalog data, not an offered character start.

-- Source: crawl-ref/source/dat/species/draconian-pale.yaml

local categories = require("constants.catalog")

local definition = {
    id = "SP_PALE_DRACONIAN",
    monster_id = "MONS_PALE_DRACONIAN",
    name = "Pale Draconian",
    short_name = "Dr",
    adjective = "Draconian",
    genus = "Draconian",
    selectable = false,
    xp = -1,
    hp = 1,
    mp_mod = 0,
    mr = 3,
    strength = 10,
    intelligence = 8,
    dexterity = 6,
    levelup_stat_frequency = 4,
    levelup_stats = {
        "str",
        "int",
        "dex",
    },
    -- Pale Draconian changes training costs through these aptitudes; current skill
    -- levels are player state.
    aptitudes = {
        SK_AIR_MAGIC = {
            allowed = true,
            value = 1,
        },
        SK_ARMOUR = {
            allowed = false,
            value = 0,
        },
        SK_AXES = {
            allowed = true,
            value = 0,
        },
        SK_CONJURATIONS = {
            allowed = true,
            value = 0,
        },
        SK_DODGING = {
            allowed = true,
            value = -1,
        },
        SK_EARTH_MAGIC = {
            allowed = true,
            value = 0,
        },
        SK_EVOCATIONS = {
            allowed = true,
            value = 1,
        },
        SK_FIGHTING = {
            allowed = true,
            value = 1,
        },
        SK_FIRE_MAGIC = {
            allowed = true,
            value = 1,
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
            value = 0,
        },
        SK_MACES_FLAILS = {
            allowed = true,
            value = 0,
        },
        SK_NECROMANCY = {
            allowed = true,
            value = 0,
        },
        SK_POISON_MAGIC = {
            allowed = true,
            value = 0,
        },
        SK_POLEARMS = {
            allowed = true,
            value = 0,
        },
        SK_RANGED_WEAPONS = {
            allowed = true,
            value = -1,
        },
        SK_SHIELDS = {
            allowed = true,
            value = 0,
        },
        SK_SHORT_BLADES = {
            allowed = true,
            value = 0,
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
            value = 0,
        },
        SK_SUMMONINGS = {
            allowed = true,
            value = 0,
        },
        SK_THROWING = {
            allowed = true,
            value = -1,
        },
        SK_TRANSLOCATIONS = {
            allowed = true,
            value = 0,
        },
        SK_TRANSMUTATIONS = {
            allowed = true,
            value = 0,
        },
        SK_UNARMED_COMBAT = {
            allowed = true,
            value = 0,
        },
    },
    mutations = {
        {
            level = 1,
            id = "MUT_COLD_BLOODED",
            amount = 1,
        },
        {
            level = 7,
            id = "MUT_STEAM_RESISTANCE",
            amount = 1,
        },
    },
    fake_mutations = {
        {
            long = "You can breathe blasts of scalding, opaque steam.",
            short = "breathe steam",
        },
    },
    flags = {
        "SPF_DRACONIAN",
    },
    habitat = "HT_LAND",
    size = "SIZE_MEDIUM",
    undead_type = "US_ALIVE",
}

register.definition(categories.SPECIES, definition)

return definition
