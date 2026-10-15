-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:2955

local categories = require("constants.catalog")

local definition = {
    id = "MONS_FIRE_GIANT",
    status = "defined",
    name = "fire giant",
    glyph = 67,
    colour_id = "RED",
    flags = {
        "M_FIGHTER",
        "M_WARM_BLOOD",
        "M_SEE_INVIS",
        "M_SPEAKS",
    },
    resistances = {
        {
            id = "MR_RES_FIRE",
            level = 2,
        },
    },
    xp_modifier = 13,
    genus_id = "MONS_GIANT",
    species_id = "MONS_FIRE_GIANT",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 80,
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 30,
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
    average_hp_10x = 960,
    ac = 8,
    ev = 4,
    spellbook_id = "MST_FIRE_GIANT",
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
    size_id = "SIZE_GIANT",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_FIRE_GIANT",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_FIRE_GIANT",
}

register.definition(categories.MONSTERS, definition)

return definition
