-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:2101

local categories = require("constants.catalog")

local definition = {
    id = "MONS_JUMPING_SPIDER",
    status = "defined",
    name = "jumping spider",
    glyph = 115,
    colour_id = "LIGHTBLUE",
    flags = {
        "M_NO_SKELETON",
        "M_WEB_IMMUNE",
    },
    resistances = {
        {
            id = "MR_RES_POISON",
            level = -1,
        },
    },
    xp_modifier = 6,
    genus_id = "MONS_SPIDER",
    species_id = "MONS_JUMPING_SPIDER",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 20,
    attacks = {
        {
            type_id = "AT_POUNCE",
            flavour_id = "AF_ENSNARE",
            damage = 20,
        },
        {
            type_id = "AT_BITE",
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
    },
    hd = 8,
    average_hp_10x = 320,
    ac = 6,
    ev = 12,
    spellbook_id = "MST_JUMPING_SPIDER",
    leaves_corpse = true,
    shout_id = "S_FAINT_SKITTER",
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
    size_id = "SIZE_SMALL",
    shape_id = "MON_SHAPE_ARACHNID",
    tile = {
        id = "TILEP_MONS_JUMPING_SPIDER",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_JUMPING_SPIDER",
}

register.definition(categories.MONSTERS, definition)

return definition
