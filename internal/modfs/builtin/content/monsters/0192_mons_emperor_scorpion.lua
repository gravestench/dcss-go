-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:2072

local categories = require("constants.catalog")

local definition = {
    id = "MONS_EMPEROR_SCORPION",
    status = "defined",
    name = "emperor scorpion",
    glyph = 115,
    colour_id = "LIGHTGREY",
    flags = {
        "M_NO_SKELETON",
        "M_WEB_IMMUNE",
    },
    resistances = {
        {
            id = "MR_RES_POISON",
            level = 1,
        },
    },
    xp_modifier = 11,
    genus_id = "MONS_SCORPION",
    species_id = "MONS_EMPEROR_SCORPION",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 60,
    attacks = {
        {
            type_id = "AT_STING",
            flavour_id = "AF_POISON",
            damage = 30,
        },
        {
            type_id = "AT_CLAW",
            flavour_id = "AF_PLAIN",
            damage = 10,
        },
        {
            type_id = "AT_CLAW",
            flavour_id = "AF_PLAIN",
            damage = 10,
        },
        {
            type_id = "AT_NONE",
            flavour_id = "AF_PLAIN",
            damage = 0,
        },
    },
    hd = 14,
    average_hp_10x = 1090,
    ac = 18,
    ev = 7,
    spellbook_id = "MST_NO_SPELLS",
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
    size_id = "SIZE_GIANT",
    shape_id = "MON_SHAPE_ARACHNID",
    tile = {
        id = "TILEP_MONS_EMPEROR_SCORPION",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_EMPEROR_SCORPION",
}

register.definition(categories.MONSTERS, definition)

return definition
