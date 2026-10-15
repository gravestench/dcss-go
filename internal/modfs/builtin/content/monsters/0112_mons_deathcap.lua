-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:931

local categories = require("constants.catalog")

local definition = {
    id = "MONS_DEATHCAP",
    status = "defined",
    name = "deathcap",
    glyph = 102,
    colour_id = "LIGHTMAGENTA",
    resistances = {
        {
            id = "MR_RES_COLD",
            level = 1,
        },
    },
    xp_modifier = 6,
    genus_id = "MONS_FUNGUS",
    species_id = "MONS_WANDERING_MUSHROOM",
    holiness = {
        "MH_UNDEAD",
    },
    willpower = 80,
    attacks = {
        {
            type_id = "AT_SPORE",
            flavour_id = "AF_CONFUSE",
            damage = 33,
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
    hd = 13,
    average_hp_10x = 520,
    ac = 5,
    spellbook_id = "MST_DEATHCAP",
    shout_id = "S_SILENT",
    intelligence_id = "I_BRAINLESS",
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
    size_id = "SIZE_TINY",
    shape_id = "MON_SHAPE_FUNGUS",
    tile = {
        id = "TILEP_MONS_DEATHCAP",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
