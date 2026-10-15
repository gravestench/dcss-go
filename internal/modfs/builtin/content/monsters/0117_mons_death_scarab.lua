-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:2913

local categories = require("constants.catalog")

local definition = {
    id = "MONS_DEATH_SCARAB",
    status = "defined",
    name = "death scarab",
    glyph = 66,
    colour_id = "BLUE",
    flags = {
        "M_NO_SKELETON",
        "M_BATTY",
        "M_WEB_IMMUNE",
    },
    xp_modifier = 12,
    genus_id = "MONS_DEATH_SCARAB",
    species_id = "MONS_DEATH_SCARAB",
    holiness = {
        "MH_UNDEAD",
    },
    willpower = 60,
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_SCARAB",
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
    hd = 8,
    average_hp_10x = 320,
    ac = 7,
    ev = 14,
    spellbook_id = "MST_NO_SPELLS",
    leaves_corpse = true,
    shout_id = "S_FAINT_SKITTER",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 30,
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
        id = "TILEP_MONS_DEATH_SCARAB",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_DEATH_SCARAB",
}

register.definition(categories.MONSTERS, definition)

return definition
