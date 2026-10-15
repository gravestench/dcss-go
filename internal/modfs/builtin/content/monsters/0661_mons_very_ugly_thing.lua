-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:2294

local categories = require("constants.catalog")

local definition = {
    id = "MONS_VERY_UGLY_THING",
    status = "defined",
    name = "very ugly thing",
    glyph = 117,
    colour_id = "COLOUR_UNDEF",
    flags = {
        "M_WARM_BLOOD",
        "M_HERD",
        "M_NO_GEN_DERIVED",
        "M_GHOST_DEMON",
    },
    xp_modifier = 10,
    genus_id = "MONS_UGLY_THING",
    species_id = "MONS_VERY_UGLY_THING",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 40,
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 27,
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
    hd = 18,
    average_hp_10x = 990,
    ac = 6,
    ev = 10,
    spellbook_id = "MST_NO_SPELLS",
    leaves_corpse = true,
    shout_id = "S_GURGLE",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 10,
    energy = {
        move = 9,
        swim = 9,
        attack = 10,
        missile = 10,
        spell = 10,
        special = 10,
        item = 10,
        pickup_percent = 100,
    },
    item_use_id = "MONUSE_OPEN_DOORS",
    size_id = "SIZE_LARGE",
    shape_id = "MON_SHAPE_MISC",
    tile = {
        id = "TILEP_MONS_PROGRAM_BUG",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_VERY_UGLY_THING",
}

register.definition(categories.MONSTERS, definition)

return definition
