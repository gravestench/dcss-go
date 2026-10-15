-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:2420

local categories = require("constants.catalog")

local definition = {
    id = "MONS_DART_SLUG",
    status = "defined",
    name = "dart slug",
    glyph = 119,
    colour_id = "CYAN",
    flags = {
        "M_NO_SKELETON",
    },
    resistances = {
        {
            id = "MR_RES_POISON",
            level = -1,
        },
    },
    xp_modifier = 40,
    genus_id = "MONS_ELEPHANT_SLUG",
    species_id = "MONS_DART_SLUG",
    holiness = {
        "MH_NATURAL",
    },
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_PLAIN",
            damage = 3,
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
    hd = 1,
    average_hp_10x = 100,
    ac = 1,
    ev = 1,
    spellbook_id = "MST_DART_SLUG",
    leaves_corpse = true,
    shout_id = "S_SILENT",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 7,
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
    size_id = "SIZE_LITTLE",
    shape_id = "MON_SHAPE_SNAIL",
    tile = {
        id = "TILEP_MONS_DART_SLUG",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_DART_SLUG",
}

register.definition(categories.MONSTERS, definition)

return definition
