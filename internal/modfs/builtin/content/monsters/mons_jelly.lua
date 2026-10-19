-- jelly (MONS_JELLY) is a DCSS monster profile with 3 hit dice and speed 10.
-- Its first melee contact is AT_HIT for 3 base damage; combat policy applies
-- defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local curves = require("constants.population_curves")

local definition = {
    id = "MONS_JELLY",
    status = "defined",
    name = "jelly",
    glyph = 74,
    colour_id = "LIGHTRED",
    flags = {
        "M_SEE_INVIS",
        "M_UNBLINDABLE",
        "M_SPLITS",
        "M_ACID_SPLASH",
        "M_EAT_DOORS",
        "M_WEB_IMMUNE",
        "M_NO_SKELETON",
    },
    resistances = {
        {
            id = "MR_RES_POISON",
            level = 1,
        },
        {
            id = "MR_RES_ACID",
            level = 3,
        },
    },
    xp_modifier = 15,
    genus_id = "MONS_JELLY",
    species_id = "MONS_JELLY",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 10,
    -- jelly offers AT_HIT as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_ACID",
            damage = 3,
        },
        {
            type_id = "AT_NONE",
            flavour_id = "AF_PLAIN",
            damage = 0,
        },
        {
            type_id = "AT_NONE",
            flavour_id = "AF_PLAIN",
            damage = 0,
        },
        {
            type_id = "AT_NONE",
            flavour_id = "AF_PLAIN",
            damage = 0,
        },
    },
    hd = 3,
    average_hp_10x = 165,
    ev = 2,
    spellbook_id = "MST_NO_SPELLS",
    shout_id = "S_SILENT",
    intelligence_id = "I_BRAINLESS",
    habitat_id = "HT_AMPHIBIOUS",
    speed = 10,
    -- For jelly, energy costs combine with speed 10 to determine action cadence,
    -- not an unconditional action each turn.
    energy = {
        move = 10,
        swim = 10,
        attack = 10,
        missile = 10,
        spell = 10,
        special = 10,
        item = 10,
        pickup_percent = 100,
    },
    item_use_id = "MONUSE_NOTHING",
    size_id = "SIZE_SMALL",
    shape_id = "MON_SHAPE_BLOB",
    tile = {
        id = "TILEP_MONS_JELLY",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
    -- Spawn rows place jelly in depth bands beginning at 4 through 8; they do not
    -- mutate existing actors.
    population = {
        {
            source_order = 26,
            min_depth = 4,
            max_depth = 8,
            rarity = 500,
            curve = curves.PEAK,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
