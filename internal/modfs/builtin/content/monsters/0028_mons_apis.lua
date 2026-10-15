-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:5024

local categories = require("constants.catalog")

local definition = {
    id = "MONS_APIS",
    status = "defined",
    name = "apis",
    glyph = 89,
    colour_id = "WHITE",
    flags = {
        "M_WARM_BLOOD",
    },
    xp_modifier = 8,
    genus_id = "MONS_APIS",
    species_id = "MONS_APIS",
    holiness = {
        "MH_HOLY",
    },
    willpower = 100,
    attacks = {
        {
            type_id = "AT_GORE",
            flavour_id = "AF_HOLY",
            damage = 40,
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
    average_hp_10x = 1200,
    ac = 9,
    ev = 5,
    spellbook_id = "MST_NO_SPELLS",
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
    size_id = "SIZE_LARGE",
    shape_id = "MON_SHAPE_QUADRUPED",
    tile = {
        id = "TILEP_MONS_APIS",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_APIS",
}

register.definition(categories.MONSTERS, definition)

return definition
