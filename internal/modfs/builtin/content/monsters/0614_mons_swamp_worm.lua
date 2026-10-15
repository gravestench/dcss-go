-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:2394

local categories = require("constants.catalog")

local definition = {
    id = "MONS_SWAMP_WORM",
    status = "defined",
    name = "swamp worm",
    glyph = 119,
    colour_id = "BROWN",
    flags = {
        "M_NO_SKELETON",
    },
    xp_modifier = 3,
    genus_id = "MONS_WORM",
    species_id = "MONS_SWAMP_WORM",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 10,
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_PLAIN",
            damage = 26,
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
    hd = 10,
    average_hp_10x = 350,
    ac = 3,
    ev = 12,
    spellbook_id = "MST_SWAMP_WORM",
    leaves_corpse = true,
    shout_id = "S_SILENT",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_AMPHIBIOUS",
    speed = 12,
    energy = {
        move = 12,
        swim = 12,
        attack = 10,
        missile = 10,
        spell = 10,
        special = 10,
        item = 10,
        pickup_percent = 100,
    },
    item_use_id = "MONUSE_NOTHING",
    size_id = "SIZE_MEDIUM",
    shape_id = "MON_SHAPE_SNAKE",
    tile = {
        id = "TILEP_MONS_SWAMP_WORM",
        variation_id = "TVARY_WATER",
    },
    corpse_tile_id = "TILE_CORPSE_SWAMP_WORM",
}

register.definition(categories.MONSTERS, definition)

return definition
