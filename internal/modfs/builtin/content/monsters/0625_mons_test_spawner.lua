-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:7857

local categories = require("constants.catalog")

local definition = {
    id = "MONS_TEST_SPAWNER",
    status = "defined",
    name = "test spawner",
    glyph = 88,
    colour_id = "WHITE",
    flags = {
        "M_STATIONARY",
        "M_INSUBSTANTIAL",
        "M_NO_POLY_TO",
        "M_FAST_REGEN",
    },
    resistances = {
        {
            id = "MR_RES_ELEC",
            level = 4,
        },
        {
            id = "MR_RES_FIRE",
            level = 4,
        },
        {
            id = "MR_RES_COLD",
            level = 4,
        },
        {
            id = "MR_RES_MIASMA",
            level = 4,
        },
        {
            id = "MR_RES_ACID",
            level = 4,
        },
        {
            id = "MR_RES_STICKY_FLAME",
            level = 1,
        },
    },
    xp_modifier = 15,
    genus_id = "MONS_TEST_SPAWNER",
    species_id = "MONS_TEST_SPAWNER",
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
    hd = 1000,
    average_hp_10x = 10000000,
    ac = 127,
    ev = 127,
    spellbook_id = "MST_TEST_SPAWNER",
    shout_id = "S_SILENT",
    intelligence_id = "I_BRAINLESS",
    habitat_id = "HT_AMPHIBIOUS",
    speed = 14,
    energy = {
        move = 10,
        swim = 6,
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
        id = "TILEP_MONS_TEST_SPAWNER",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
