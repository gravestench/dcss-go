-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:2433

local categories = require("constants.catalog")

local definition = {
    id = "MONS_TORPOR_SNAIL",
    status = "defined",
    name = "torpor snail",
    glyph = 119,
    colour_id = "GREEN",
    flags = {
        "M_NO_SKELETON",
        "M_WEB_IMMUNE",
    },
    xp_modifier = 20,
    genus_id = "MONS_ELEPHANT_SLUG",
    species_id = "MONS_TORPOR_SNAIL",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 80,
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_PLAIN",
            damage = 25,
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
    average_hp_10x = 600,
    ac = 8,
    ev = 1,
    spellbook_id = "MST_NO_SPELLS",
    leaves_corpse = true,
    shout_id = "S_SILENT",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_AMPHIBIOUS",
    speed = 7,
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
    size_id = "SIZE_LARGE",
    shape_id = "MON_SHAPE_SNAIL",
    tile = {
        id = "TILEP_MONS_TORPOR_SNAIL",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_TORPOR_SNAIL",
}

register.definition(categories.MONSTERS, definition)

return definition
