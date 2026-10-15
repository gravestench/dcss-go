-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:4712

local categories = require("constants.catalog")

local definition = {
    id = "MONS_DROWNED_SOUL",
    status = "defined",
    name = "drowned soul",
    glyph = 87,
    colour_id = "LIGHTCYAN",
    flags = {
        "M_SEE_INVIS",
        "M_INSUBSTANTIAL",
        "M_SPEAKS",
        "M_FLIES",
    },
    resistances = {
        {
            id = "MR_RES_COLD",
            level = 3,
        },
    },
    xp_modifier = 8,
    genus_id = "MONS_PHANTOM",
    species_id = "MONS_DROWNED_SOUL",
    holiness = {
        "MH_UNDEAD",
    },
    willpower = 60,
    attacks = {
        {
            type_id = "AT_TOUCH",
            flavour_id = "AF_DROWN",
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
        {
            type_id = "AT_NONE",
            flavour_id = "AF_PLAIN",
            damage = 0,
        },
    },
    hd = 13,
    average_hp_10x = 195,
    ev = 13,
    spellbook_id = "MST_NO_SPELLS",
    shout_id = "S_SILENT",
    intelligence_id = "I_HUMAN",
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
    item_use_id = "MONUSE_OPEN_DOORS",
    size_id = "SIZE_MEDIUM",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_DROWNED_SOUL",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
