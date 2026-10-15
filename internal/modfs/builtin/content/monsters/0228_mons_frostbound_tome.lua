-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:5506

local categories = require("constants.catalog")

local definition = {
    id = "MONS_FROSTBOUND_TOME",
    status = "defined",
    name = "walking frostbound tome",
    glyph = 59,
    colour_id = "YELLOW",
    resistances = {
        {
            id = "MR_RES_COLD",
            level = 1,
        },
        {
            id = "MR_RES_FIRE",
            level = -1,
        },
    },
    xp_modifier = 14,
    genus_id = "MONS_WALKING_TOME",
    species_id = "MONS_EARTHEN_TOME",
    holiness = {
        "MH_NONLIVING",
    },
    willpower = 5000,
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_COLD",
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
    hd = 20,
    average_hp_10x = 1000,
    ac = 10,
    ev = 10,
    spellbook_id = "MST_WALKING_TOME",
    shout_id = "S_RUSTLE",
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
    size_id = "SIZE_SMALL",
    shape_id = "MON_SHAPE_MISC",
    tile = {
        id = "TILEP_MONS_FROSTBOUND_TOME",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
