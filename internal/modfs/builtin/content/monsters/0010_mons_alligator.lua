-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:2196

local categories = require("constants.catalog")

local definition = {
    id = "MONS_ALLIGATOR",
    status = "defined",
    name = "alligator",
    glyph = 116,
    colour_id = "LIGHTBLUE",
    flags = {
        "M_COLD_BLOOD",
    },
    xp_modifier = 10,
    genus_id = "MONS_GIANT_LIZARD",
    species_id = "MONS_ALLIGATOR",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 40,
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_PLAIN",
            damage = 30,
        },
        {
            type_id = "AT_TAIL_SLAP",
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
    hd = 12,
    average_hp_10x = 720,
    ac = 5,
    ev = 9,
    spellbook_id = "MST_ALLIGATOR",
    leaves_corpse = true,
    shout_id = "S_SILENT",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_AMPHIBIOUS",
    speed = 10,
    energy = {
        move = 10,
        swim = 6,
        attack = 8,
        missile = 8,
        spell = 8,
        special = 8,
        item = 8,
        pickup_percent = 80,
    },
    item_use_id = "MONUSE_NOTHING",
    size_id = "SIZE_LARGE",
    shape_id = "MON_SHAPE_QUADRUPED",
    tile = {
        id = "TILEP_MONS_ALLIGATOR",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_ALLIGATOR",
}

register.definition(categories.MONSTERS, definition)

return definition
