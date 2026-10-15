-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:7783

local categories = require("constants.catalog")

local definition = {
    id = "MONS_GLOORX_VLOQ",
    status = "defined",
    name = "Gloorx Vloq",
    glyph = 38,
    colour_id = "LIGHTGREY",
    flags = {
        "M_UNIQUE",
        "M_FIGHTER",
        "M_SEE_INVIS",
        "M_SPEAKS",
        "M_FLIES",
        "M_TALL_TILE",
        "M_GENDER_NEUTRAL",
    },
    resistances = {
        {
            id = "MR_RES_POISON",
            level = 1,
        },
        {
            id = "MR_RES_COLD",
            level = 1,
        },
        {
            id = "MR_RES_ELEC",
            level = 1,
        },
    },
    xp_modifier = 15,
    genus_id = "MONS_PANDEMONIUM_LORD",
    species_id = "MONS_GLOORX_VLOQ",
    holiness = {
        "MH_DEMONIC",
    },
    willpower = 5000,
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 45,
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
    hd = 16,
    average_hp_10x = 3520,
    ac = 10,
    ev = 10,
    spellbook_id = "MST_GLOORX_VLOQ",
    shout_id = "S_MOAN",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 20,
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
        id = "TILEP_MONS_GLOORX_VLOQ",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
