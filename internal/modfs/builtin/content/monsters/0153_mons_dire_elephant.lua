-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:4996

local categories = require("constants.catalog")

local definition = {
    id = "MONS_DIRE_ELEPHANT",
    status = "defined",
    name = "dire elephant",
    glyph = 89,
    colour_id = "BLUE",
    flags = {
        "M_WARM_BLOOD",
    },
    xp_modifier = 8,
    genus_id = "MONS_ELEPHANT",
    species_id = "MONS_DIRE_ELEPHANT",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 100,
    attacks = {
        {
            type_id = "AT_TRAMPLE",
            flavour_id = "AF_TRAMPLE",
            damage = 40,
        },
        {
            type_id = "AT_TRUNK_SLAP",
            flavour_id = "AF_PLAIN",
            damage = 15,
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
    average_hp_10x = 1125,
    ac = 13,
    ev = 2,
    spellbook_id = "MST_NO_SPELLS",
    leaves_corpse = true,
    shout_id = "S_TRUMPET",
    intelligence_id = "I_ANIMAL",
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
    size_id = "SIZE_GIANT",
    shape_id = "MON_SHAPE_QUADRUPED",
    tile = {
        id = "TILEP_MONS_DIRE_ELEPHANT",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_DIRE_ELEPHANT",
}

register.definition(categories.MONSTERS, definition)

return definition
