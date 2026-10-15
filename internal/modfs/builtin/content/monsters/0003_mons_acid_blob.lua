-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:3743

local categories = require("constants.catalog")

local definition = {
    id = "MONS_ACID_BLOB",
    status = "defined",
    name = "acid blob",
    glyph = 74,
    colour_id = "LIGHTCYAN",
    flags = {
        "M_SEE_INVIS",
        "M_UNBLINDABLE",
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
    xp_modifier = 12,
    genus_id = "MONS_JELLY",
    species_id = "MONS_ACID_BLOB",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 160,
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_ACID",
            damage = 42,
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
    hd = 18,
    average_hp_10x = 990,
    ac = 1,
    ev = 3,
    spellbook_id = "MST_ACID_SPIT",
    shout_id = "S_SILENT",
    intelligence_id = "I_BRAINLESS",
    habitat_id = "HT_LAND",
    speed = 12,
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
        id = "TILEP_MONS_ACID_BLOB",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
