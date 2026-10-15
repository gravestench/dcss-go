-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:6832

local categories = require("constants.catalog")

local definition = {
    id = "MONS_PRINCE_RIBBIT",
    status = "defined",
    name = "Prince Ribbit",
    glyph = 70,
    colour_id = "LIGHTCYAN",
    flags = {
        "M_UNIQUE",
        "M_COLD_BLOOD",
        "M_SPEAKS",
        "M_MALE",
    },
    xp_modifier = 12,
    genus_id = "MONS_FROG",
    species_id = "MONS_HUMAN",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 40,
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 20,
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
    hd = 6,
    average_hp_10x = 390,
    ev = 16,
    spellbook_id = "MST_BLINKER",
    leaves_corpse = true,
    shout_id = "S_CROAK",
    intelligence_id = "I_HUMAN",
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
    size_id = "SIZE_MEDIUM",
    shape_id = "MON_SHAPE_QUADRUPED_TAILLESS",
    tile = {
        id = "TILEP_MONS_PRINCE_RIBBIT",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
