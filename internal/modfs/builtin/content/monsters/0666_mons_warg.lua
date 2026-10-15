-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:1130

local categories = require("constants.catalog")

local definition = {
    id = "MONS_WARG",
    status = "defined",
    name = "warg",
    glyph = 104,
    colour_id = "WHITE",
    flags = {
        "M_SEE_INVIS",
        "M_UNBLINDABLE",
        "M_WARM_BLOOD",
    },
    resistances = {
        {
            id = "MR_RES_POISON",
            level = 1,
        },
    },
    xp_modifier = 12,
    genus_id = "MONS_HOUND",
    species_id = "MONS_WARG",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 40,
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_PLAIN",
            damage = 18,
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
    hd = 5,
    average_hp_10x = 325,
    ac = 4,
    ev = 12,
    spellbook_id = "MST_NO_SPELLS",
    leaves_corpse = true,
    shout_id = "S_HOWL",
    intelligence_id = "I_ANIMAL",
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
    item_use_id = "MONUSE_NOTHING",
    size_id = "SIZE_LARGE",
    shape_id = "MON_SHAPE_QUADRUPED",
    tile = {
        id = "TILEP_MONS_WARG",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_WARG",
}

register.definition(categories.MONSTERS, definition)

return definition
