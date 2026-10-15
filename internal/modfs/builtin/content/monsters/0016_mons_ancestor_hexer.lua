-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:3646

local categories = require("constants.catalog")

local definition = {
    id = "MONS_ANCESTOR_HEXER",
    status = "defined",
    name = "hexer",
    glyph = 82,
    colour_id = "LIGHTCYAN",
    flags = {
        "M_ANCESTOR",
        "M_NO_POLY_TO",
        "M_NO_GEN_DERIVED",
        "M_FLIES",
        "M_FAST_REGEN",
        "M_INSUBSTANTIAL",
        "M_SEE_INVIS",
    },
    resistances = {
        {
            id = "MR_RES_FIRE",
            level = 1,
        },
        {
            id = "MR_RES_COLD",
            level = 1,
        },
    },
    xp_modifier = 1,
    genus_id = "MONS_ANCESTOR",
    species_id = "MONS_ANCESTOR_HEXER",
    holiness = {
        "MH_NONLIVING",
    },
    willpower = -5,
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 27,
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
    hd = 1,
    average_hp_10x = 1,
    ac = 5,
    ev = 10,
    spellbook_id = "MST_NO_SPELLS",
    shout_id = "S_SHOUT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    energy = {
        move = 10,
        swim = 10,
        attack = 5,
        missile = 10,
        spell = 10,
        special = 10,
        item = 10,
        pickup_percent = 100,
    },
    item_use_id = "MONUSE_STARTING_EQUIPMENT",
    size_id = "SIZE_MEDIUM",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_ANCESTOR_HEXER",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
