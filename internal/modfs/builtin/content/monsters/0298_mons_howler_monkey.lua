-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:1117

local categories = require("constants.catalog")

local definition = {
    id = "MONS_HOWLER_MONKEY",
    status = "defined",
    name = "howler monkey",
    glyph = 104,
    colour_id = "LIGHTGREEN",
    flags = {
        "M_WARM_BLOOD",
    },
    xp_modifier = 15,
    genus_id = "MONS_HOWLER_MONKEY",
    species_id = "MONS_HOWLER_MONKEY",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 10,
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 8,
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
    hd = 3,
    average_hp_10x = 185,
    ac = 1,
    ev = 11,
    spellbook_id = "MST_SCREAMER",
    leaves_corpse = true,
    shout_id = "S_HOWL",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 12,
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
    shape_id = "MON_SHAPE_HUMANOID_TAILED",
    tile = {
        id = "TILEP_MONS_HOWLER_MONKEY",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_HOWLER_MONKEY",
}

register.definition(categories.MONSTERS, definition)

return definition
