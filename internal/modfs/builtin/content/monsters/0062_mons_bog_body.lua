-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:1587

local categories = require("constants.catalog")

local definition = {
    id = "MONS_BOG_BODY",
    status = "defined",
    name = "bog body",
    glyph = 110,
    colour_id = "GREEN",
    flags = {
        "M_NO_ZOMBIE",
    },
    resistances = {
        {
            id = "MR_RES_FIRE",
            level = 1,
        },
        {
            id = "MR_RES_COLD",
            level = 1,
        },
    },
    xp_modifier = 16,
    genus_id = "MONS_GHOUL",
    species_id = "MONS_BOG_BODY",
    holiness = {
        "MH_UNDEAD",
    },
    willpower = 40,
    attacks = {
        {
            type_id = "AT_TOUCH",
            flavour_id = "AF_COLD",
            damage = 20,
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
    hd = 10,
    average_hp_10x = 390,
    ac = 1,
    ev = 9,
    spellbook_id = "MST_BOG_BODY",
    leaves_corpse = true,
    shout_id = "S_SILENT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_AMPHIBIOUS",
    speed = 10,
    energy = {
        move = 10,
        swim = 14,
        attack = 10,
        missile = 10,
        spell = 10,
        special = 10,
        item = 10,
        pickup_percent = 100,
    },
    item_use_id = "MONUSE_OPEN_DOORS",
    size_id = "SIZE_MEDIUM",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_BOG_BODY",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_BOG_BODY",
}

register.definition(categories.MONSTERS, definition)

return definition
