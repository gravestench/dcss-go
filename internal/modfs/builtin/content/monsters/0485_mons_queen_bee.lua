-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:2554

local categories = require("constants.catalog")

local definition = {
    id = "MONS_QUEEN_BEE",
    status = "defined",
    name = "queen bee",
    glyph = 121,
    colour_id = "LIGHTMAGENTA",
    flags = {
        "M_NO_SKELETON",
        "M_FLIES",
    },
    resistances = {
        {
            id = "MR_RES_POISON",
            level = -1,
        },
    },
    xp_modifier = 14,
    genus_id = "MONS_KILLER_BEE",
    species_id = "MONS_QUEEN_BEE",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 20,
    attacks = {
        {
            type_id = "AT_STING",
            flavour_id = "AF_POISON",
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
    hd = 7,
    average_hp_10x = 385,
    ac = 10,
    ev = 10,
    spellbook_id = "MST_QUEEN_BEE",
    leaves_corpse = true,
    shout_id = "S_BUZZ",
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
    size_id = "SIZE_LITTLE",
    shape_id = "MON_SHAPE_INSECT_WINGED",
    tile = {
        id = "TILEP_MONS_QUEEN_BEE",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_QUEEN_BEE",
}

register.definition(categories.MONSTERS, definition)

return definition
