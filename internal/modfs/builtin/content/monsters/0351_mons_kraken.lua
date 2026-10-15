-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:5228

local categories = require("constants.catalog")

local definition = {
    id = "MONS_KRAKEN",
    status = "defined",
    name = "kraken",
    glyph = 88,
    colour_id = "LIGHTMAGENTA",
    flags = {
        "M_NO_SKELETON",
        "M_COLD_BLOOD",
    },
    xp_modifier = 6,
    genus_id = "MONS_KRAKEN",
    species_id = "MONS_KRAKEN",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 60,
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_PLAIN",
            damage = 50,
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
    average_hp_10x = 2080,
    ac = 20,
    spellbook_id = "MST_KRAKEN",
    leaves_corpse = true,
    shout_id = "S_SILENT",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_WATER",
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
    shape_id = "MON_SHAPE_MISC",
    tile = {
        id = "TILEP_MONS_KRAKEN_HEAD",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_KRAKEN",
}

register.definition(categories.MONSTERS, definition)

return definition
