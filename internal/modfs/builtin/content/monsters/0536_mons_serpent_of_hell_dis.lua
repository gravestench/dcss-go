-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:6748

local categories = require("constants.catalog")

local definition = {
    id = "MONS_SERPENT_OF_HELL_DIS",
    status = "defined",
    name = "the Serpent of Hell",
    glyph = 68,
    colour_id = "ETC_IRON",
    flags = {
        "M_SEE_INVIS",
        "M_UNIQUE",
        "M_CRASH_DOORS",
        "M_TALL_TILE",
    },
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
    xp_modifier = 16,
    genus_id = "MONS_DRAGON",
    species_id = "MONS_SERPENT_OF_HELL",
    holiness = {
        "MH_DEMONIC",
    },
    willpower = 180,
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_REACH",
            damage = 35,
        },
        {
            type_id = "AT_CLAW",
            flavour_id = "AF_PLAIN",
            damage = 25,
        },
        {
            type_id = "AT_TRAMPLE",
            flavour_id = "AF_TRAMPLE",
            damage = 25,
        },
        {
            type_id = "AT_TAIL_SLAP",
            flavour_id = "AF_PLAIN",
            damage = 15,
        },
    },
    hd = 17,
    average_hp_10x = 3230,
    ac = 30,
    ev = 8,
    spellbook_id = "MST_SERPENT_OF_HELL_DIS",
    shout_id = "S_LOUD_ROAR",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 14,
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
    size_id = "SIZE_GIANT",
    shape_id = "MON_SHAPE_QUADRUPED_WINGED",
    tile = {
        id = "TILEP_MONS_SERPENT_OF_HELL_DIS",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
