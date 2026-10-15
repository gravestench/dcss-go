-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:2606

local categories = require("constants.catalog")

local definition = {
    id = "MONS_SPARK_WASP",
    status = "defined",
    name = "spark wasp",
    glyph = 121,
    colour_id = "LIGHTCYAN",
    flags = {
        "M_NO_SKELETON",
        "M_FLIES",
        "M_WEB_IMMUNE",
    },
    resistances = {
        {
            id = "MR_RES_ELEC",
            level = 3,
        },
        {
            id = "MR_RES_POISON",
            level = -1,
        },
    },
    xp_modifier = 12,
    genus_id = "MONS_SPARK_WASP",
    species_id = "MONS_SPARK_WASP",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 40,
    attacks = {
        {
            type_id = "AT_STING",
            flavour_id = "AF_ELEC",
            damage = 33,
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
    hd = 12,
    average_hp_10x = 660,
    ac = 9,
    ev = 14,
    spellbook_id = "MST_SPARK_WASP",
    leaves_corpse = true,
    shout_id = "S_BUZZ",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 15,
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
    size_id = "SIZE_TINY",
    shape_id = "MON_SHAPE_INSECT_WINGED",
    tile = {
        id = "TILEP_MONS_SPARK_WASP",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_SPARK_WASP",
}

register.definition(categories.MONSTERS, definition)

return definition
