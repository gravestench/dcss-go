-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:5634

local categories = require("constants.catalog")

local definition = {
    id = "MONS_QUASIT",
    status = "defined",
    name = "quasit",
    glyph = 53,
    colour_id = "LIGHTGREY",
    resistances = {
        {
            id = "MR_RES_POISON",
            level = 1,
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
    xp_modifier = 13,
    genus_id = "MONS_QUASIT",
    species_id = "MONS_QUASIT",
    holiness = {
        "MH_DEMONIC",
    },
    willpower = 10,
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_DRAIN_DEX",
            damage = 3,
        },
        {
            type_id = "AT_CLAW",
            flavour_id = "AF_DRAIN_DEX",
            damage = 2,
        },
        {
            type_id = "AT_CLAW",
            flavour_id = "AF_DRAIN_DEX",
            damage = 2,
        },
        {
            type_id = "AT_NONE",
            flavour_id = "AF_PLAIN",
            damage = 0,
        },
    },
    hd = 3,
    average_hp_10x = 150,
    ac = 5,
    ev = 17,
    spellbook_id = "MST_NO_SPELLS",
    shout_id = "S_MOAN",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 13,
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
    size_id = "SIZE_SMALL",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_QUASIT",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
