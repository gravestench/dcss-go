-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:5566

local categories = require("constants.catalog")

local definition = {
    id = "MONS_DEMONSPAWN_BLOOD_SAINT",
    status = "defined",
    name = "demonspawn blood saint",
    glyph = 54,
    colour_id = "LIGHTBLUE",
    flags = {
        "M_WARM_BLOOD",
        "M_SPEAKS",
    },
    resistances = {
        {
            id = "MR_RES_FIRE",
            level = 3,
        },
    },
    xp_modifier = 10,
    genus_id = "MONS_DEMONSPAWN",
    species_id = "MONS_DEMONSPAWN",
    holiness = {
        "MH_NATURAL",
        "MH_DEMONIC",
    },
    willpower = 60,
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_FIRE",
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
    hd = 15,
    average_hp_10x = 925,
    ac = 6,
    ev = 12,
    spellbook_id = "MST_DEMONSPAWN_BLOOD_SAINT",
    leaves_corpse = true,
    shout_id = "S_SHOUT",
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
    item_use_id = "MONUSE_WEAPONS_ARMOUR",
    size_id = "SIZE_MEDIUM",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_DEMONSPAWN_BLOOD_SAINT",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
