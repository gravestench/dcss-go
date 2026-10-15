-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:6476

local categories = require("constants.catalog")

local definition = {
    id = "MONS_CREEPING_INFERNO",
    status = "defined",
    name = "creeping inferno",
    glyph = 42,
    colour_id = "LIGHTRED",
    flags = {
        "M_INSUBSTANTIAL",
        "M_FLIES",
        "M_NO_EXP_GAIN",
    },
    resistances = {
        {
            id = "MR_RES_FIRE",
            level = 3,
        },
    },
    xp_modifier = 10,
    genus_id = "MONS_CREEPING_INFERNO",
    species_id = "MONS_CREEPING_INFERNO",
    holiness = {
        "MH_NONLIVING",
    },
    willpower = 10,
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 1,
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
    hd = 15,
    average_hp_10x = 10,
    ev = 10,
    spellbook_id = "MST_NO_SPELLS",
    shout_id = "S_SILENT",
    intelligence_id = "I_BRAINLESS",
    habitat_id = "HT_LAND",
    speed = 14,
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
    shape_id = "MON_SHAPE_ORB",
    tile = {
        id = "TILEP_MONS_CREEPING_INFERNO",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
