-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:6489

local categories = require("constants.catalog")

local definition = {
    id = "MONS_ORB_OF_DESTRUCTION",
    status = "defined",
    name = "orb of destruction",
    glyph = 42,
    colour_id = "WHITE",
    flags = {
        "M_INSUBSTANTIAL",
        "M_NO_EXP_GAIN",
        "M_NO_THREAT",
        "M_NO_POLY_TO",
        "M_PROJECTILE",
        "M_FLIES",
    },
    resistances = {
        {
            id = "MR_RES_COLD",
            level = 3,
        },
        {
            id = "MR_RES_ELEC",
            level = 3,
        },
        {
            id = "MR_RES_ACID",
            level = 3,
        },
        {
            id = "MR_RES_FIRE",
            level = 3,
        },
        {
            id = "MR_RES_DAMNATION",
            level = 1,
        },
        {
            id = "MR_RES_STICKY_FLAME",
            level = 1,
        },
    },
    genus_id = "MONS_ORB_OF_DESTRUCTION",
    species_id = "MONS_ORB_OF_DESTRUCTION",
    holiness = {
        "MH_NONLIVING",
    },
    willpower = 5000,
    attacks = {
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
        {
            type_id = "AT_NONE",
            flavour_id = "AF_PLAIN",
            damage = 0,
        },
    },
    hd = 5,
    average_hp_10x = 50000,
    ev = 10,
    spellbook_id = "MST_NO_SPELLS",
    shout_id = "S_SILENT",
    intelligence_id = "I_BRAINLESS",
    habitat_id = "HT_LAND",
    speed = 30,
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
    size_id = "SIZE_LITTLE",
    shape_id = "MON_SHAPE_ORB",
    tile = {
        id = "TILEP_MONS_ORB_OF_DESTRUCTION",
        variation_id = "TVARY_RANDOM",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
