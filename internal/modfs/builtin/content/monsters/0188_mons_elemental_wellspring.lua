-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:3321

local categories = require("constants.catalog")

local definition = {
    id = "MONS_ELEMENTAL_WELLSPRING",
    status = "defined",
    name = "elemental wellspring",
    glyph = 69,
    colour_id = "LIGHTCYAN",
    flags = {
        "M_UNBLINDABLE",
    },
    resistances = {
        {
            id = "MR_RES_ELEC",
            level = 1,
        },
    },
    xp_modifier = 13,
    genus_id = "MONS_ELEMENTAL",
    species_id = "MONS_ELEMENTAL_WELLSPRING",
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
    hd = 18,
    average_hp_10x = 620,
    ac = 8,
    ev = 8,
    spellbook_id = "MST_ELEMENTAL_WELLSPRING",
    shout_id = "S_SILENT",
    intelligence_id = "I_BRAINLESS",
    habitat_id = "HT_WATER",
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
    size_id = "SIZE_LARGE",
    shape_id = "MON_SHAPE_MISC",
    tile = {
        id = "TILEP_MONS_ELEMENTAL_WELLSPRING",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
