-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:2844

local categories = require("constants.catalog")

local definition = {
    id = "MONS_RADROACH",
    status = "defined",
    name = "radroach",
    glyph = 66,
    colour_id = "LIGHTRED",
    flags = {
        "M_NO_SKELETON",
        "M_WEB_IMMUNE",
    },
    xp_modifier = 10,
    genus_id = "MONS_GIANT_COCKROACH",
    species_id = "MONS_RADROACH",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 60,
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_PLAIN",
            damage = 28,
        },
        {
            type_id = "AT_CLAW",
            flavour_id = "AF_PLAIN",
            damage = 16,
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
    hd = 12,
    average_hp_10x = 800,
    ac = 13,
    ev = 5,
    spellbook_id = "MST_RADROACH",
    leaves_corpse = true,
    shout_id = "S_SILENT",
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
    size_id = "SIZE_LITTLE",
    shape_id = "MON_SHAPE_INSECT",
    tile = {
        id = "TILEP_MONS_RADROACH",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_RADROACH",
}

register.definition(categories.MONSTERS, definition)

return definition
