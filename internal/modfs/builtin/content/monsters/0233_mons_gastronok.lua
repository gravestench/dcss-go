-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:7351

local categories = require("constants.catalog")

local definition = {
    id = "MONS_GASTRONOK",
    status = "defined",
    name = "Gastronok",
    glyph = 119,
    colour_id = "MAGENTA",
    flags = {
        "M_UNIQUE",
        "M_SEE_INVIS",
        "M_SPEAKS",
        "M_NO_WAND",
        "M_MALE",
    },
    xp_modifier = 16,
    genus_id = "MONS_ELEPHANT_SLUG",
    species_id = "MONS_ELEPHANT_SLUG",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 80,
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_PLAIN",
            damage = 40,
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
    hd = 20,
    average_hp_10x = 1500,
    ac = 2,
    ev = 1,
    spellbook_id = "MST_GASTRONOK",
    leaves_corpse = true,
    shout_id = "S_GURGLE",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_AMPHIBIOUS",
    speed = 5,
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
    item_use_id = "MONUSE_STARTING_EQUIPMENT",
    size_id = "SIZE_GIANT",
    shape_id = "MON_SHAPE_SNAIL",
    tile = {
        id = "TILEP_MONS_GASTRONOK",
        variation_id = "TVARY_MOD",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
