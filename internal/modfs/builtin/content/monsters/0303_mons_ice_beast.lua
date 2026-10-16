-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:5037

local categories = require("constants.catalog")
local curves = require("constants.population_curves")

local definition = {
    id = "MONS_ICE_BEAST",
    status = "defined",
    name = "ice beast",
    glyph = 89,
    colour_id = "LIGHTBLUE",
    flags = {
        "M_NO_SKELETON",
    },
    resistances = {
        {
            id = "MR_RES_POISON",
            level = 1,
        },
        {
            id = "MR_RES_FIRE",
            level = -1,
        },
        {
            id = "MR_RES_COLD",
            level = 3,
        },
    },
    xp_modifier = 13,
    genus_id = "MONS_ICE_BEAST",
    species_id = "MONS_ICE_BEAST",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 20,
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_COLD",
            damage = 5,
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
    hd = 5,
    average_hp_10x = 275,
    ac = 5,
    ev = 10,
    spellbook_id = "MST_NO_SPELLS",
    shout_id = "S_SILENT",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_AMPHIBIOUS",
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
    size_id = "SIZE_LARGE",
    shape_id = "MON_SHAPE_QUADRUPED",
    tile = {
        id = "TILEP_MONS_ICE_BEAST",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
    population = {
        -- Source line: 103
        {
            source_order = 35,
            min_depth = 5,
            max_depth = 8,
            rarity = 500,
            curve = curves.PEAK,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
