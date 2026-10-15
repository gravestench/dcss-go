-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:3850

local categories = require("constants.catalog")

local definition = {
    id = "MONS_STOKER",
    status = "defined",
    name = "stoker",
    glyph = 76,
    colour_id = "ETC_FIRE",
    flags = {
        "M_NO_SKELETON",
    },
    resistances = {
        {
            id = "MR_RES_FIRE",
            level = 3,
        },
    },
    xp_modifier = 10,
    genus_id = "MONS_LICH",
    species_id = "MONS_STOKER",
    holiness = {
        "MH_UNDEAD",
    },
    willpower = 120,
    attacks = {
        {
            type_id = "AT_TOUCH",
            flavour_id = "AF_FIRE",
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
        {
            type_id = "AT_NONE",
            flavour_id = "AF_PLAIN",
            damage = 0,
        },
    },
    hd = 13,
    average_hp_10x = 800,
    ac = 5,
    ev = 12,
    spellbook_id = "MST_STOKER",
    shout_id = "S_SHOUT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_AMPHIBIOUS_LAVA",
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
    size_id = "SIZE_MEDIUM",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_STOKER",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
