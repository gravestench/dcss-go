-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:3483

local categories = require("constants.catalog")

local definition = {
    id = "MONS_OPHAN",
    status = "defined",
    name = "ophan",
    glyph = 71,
    colour_id = "RED",
    flags = {
        "M_SEE_INVIS",
        "M_FLIES",
    },
    xp_modifier = 14,
    genus_id = "MONS_ANGEL",
    species_id = "MONS_OPHAN",
    holiness = {
        "MH_HOLY",
    },
    willpower = 140,
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
    hd = 15,
    average_hp_10x = 975,
    ac = 10,
    ev = 10,
    spellbook_id = "MST_OPHAN",
    shout_id = "S_SILENT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
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
    size_id = "SIZE_MEDIUM",
    shape_id = "MON_SHAPE_ORB",
    tile = {
        id = "TILEP_MONS_OPHAN",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
