-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:6545

local categories = require("constants.catalog")

local definition = {
    id = "MONS_BATTLESPHERE",
    status = "defined",
    name = "battlesphere",
    glyph = 42,
    colour_id = "ETC_MAGIC",
    flags = {
        "M_SEE_INVIS",
        "M_INSUBSTANTIAL",
        "M_NO_EXP_GAIN",
        "M_NO_POLY_TO",
        "M_MAINTAIN_RANGE",
        "M_AVATAR",
        "M_FLIES",
        "M_UNBLINDABLE",
    },
    resistances = {
        {
            id = "MR_RES_COLD",
            level = 2,
        },
        {
            id = "MR_RES_FIRE",
            level = 2,
        },
        {
            id = "MR_RES_ELEC",
            level = 3,
        },
        {
            id = "MR_RES_ACID",
            level = 1,
        },
        {
            id = "MR_RES_STICKY_FLAME",
            level = 1,
        },
    },
    genus_id = "MONS_BATTLESPHERE",
    species_id = "MONS_BATTLESPHERE",
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
    average_hp_10x = 150,
    ev = 5,
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
        id = "TILEP_MONS_BATTLESPHERE",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
