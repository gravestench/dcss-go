-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:6150

local categories = require("constants.catalog")

local definition = {
    id = "MONS_ELECTRIC_GOLEM",
    status = "defined",
    name = "electric golem",
    glyph = 57,
    colour_id = "LIGHTBLUE",
    flags = {
        "M_SEE_INVIS",
        "M_INSUBSTANTIAL",
        "M_SPEAKS",
    },
    resistances = {
        {
            id = "MR_RES_ELEC",
            level = 3,
        },
        {
            id = "MR_RES_FIRE",
            level = 1,
        },
        {
            id = "MR_RES_COLD",
            level = 1,
        },
    },
    xp_modifier = 12,
    genus_id = "MONS_GOLEM",
    species_id = "MONS_ELECTRIC_GOLEM",
    holiness = {
        "MH_NONLIVING",
    },
    willpower = 5000,
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_ELEC",
            damage = 15,
        },
        {
            type_id = "AT_HIT",
            flavour_id = "AF_ELEC",
            damage = 15,
        },
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 15,
        },
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 15,
        },
    },
    hd = 15,
    average_hp_10x = 1350,
    ac = 5,
    ev = 20,
    spellbook_id = "MST_ELECTRIC_GOLEM",
    shout_id = "S_SILENT",
    intelligence_id = "I_BRAINLESS",
    habitat_id = "HT_LAND",
    speed = 16,
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
    item_use_id = "MONUSE_OPEN_DOORS",
    size_id = "SIZE_LARGE",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_ELECTRIC_GOLEM",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
