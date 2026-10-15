-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:2648

local categories = require("constants.catalog")

local definition = {
    id = "MONS_SUN_MOTH",
    status = "defined",
    name = "sun moth",
    glyph = 121,
    colour_id = "ETC_GOLD",
    flags = {
        "M_NO_SKELETON",
        "M_FLIES",
        "M_WEB_IMMUNE",
    },
    resistances = {
        {
            id = "MR_RES_FIRE",
            level = 1,
        },
        {
            id = "MR_RES_ELEC",
            level = 1,
        },
    },
    xp_modifier = 10,
    genus_id = "MONS_MOTH",
    species_id = "MONS_SUN_MOTH",
    holiness = {
        "MH_HOLY",
    },
    willpower = 60,
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_STICKY_FLAME",
            damage = 30,
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
    hd = 9,
    average_hp_10x = 805,
    ac = 6,
    ev = 12,
    spellbook_id = "MST_SUN_MOTH",
    leaves_corpse = true,
    shout_id = "S_SILENT",
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
    item_use_id = "MONUSE_NOTHING",
    size_id = "SIZE_SMALL",
    shape_id = "MON_SHAPE_INSECT_WINGED",
    tile = {
        id = "TILEP_MONS_SUN_MOTH",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_SUN_MOTH",
}

register.definition(categories.MONSTERS, definition)

return definition
