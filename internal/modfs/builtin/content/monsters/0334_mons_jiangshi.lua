-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:4617

local categories = require("constants.catalog")

local definition = {
    id = "MONS_JIANGSHI",
    status = "defined",
    name = "jiangshi",
    glyph = 86,
    colour_id = "YELLOW",
    flags = {
        "M_FIGHTER",
    },
    resistances = {
        {
            id = "MR_RES_COLD",
            level = 1,
        },
    },
    xp_modifier = 10,
    genus_id = "MONS_JIANGSHI",
    species_id = "MONS_VAMPIRE",
    holiness = {
        "MH_UNDEAD",
    },
    willpower = 80,
    attacks = {
        {
            type_id = "AT_CLAW",
            flavour_id = "AF_VAMPIRIC",
            damage = 27,
        },
        {
            type_id = "AT_CLAW",
            flavour_id = "AF_VAMPIRIC",
            damage = 27,
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
    average_hp_10x = 650,
    ac = 10,
    ev = 10,
    spellbook_id = "MST_NO_SPELLS",
    shout_id = "S_SILENT",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 18,
    energy = {
        move = 6,
        swim = 6,
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
        id = "TILEP_MONS_JIANGSHI",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
