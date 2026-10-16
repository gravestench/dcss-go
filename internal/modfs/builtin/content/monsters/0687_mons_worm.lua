-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:2381

local categories = require("constants.catalog")
local curves = require("constants.population_curves")

local definition = {
    id = "MONS_WORM",
    status = "defined",
    name = "worm",
    glyph = 119,
    colour_id = "LIGHTRED",
    flags = {
        "M_NO_SKELETON",
        "M_FAST_REGEN",
    },
    xp_modifier = 3,
    genus_id = "MONS_WORM",
    species_id = "MONS_WORM",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 10,
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_PLAIN",
            damage = 12,
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
    hd = 4,
    average_hp_10x = 180,
    ac = 1,
    ev = 5,
    spellbook_id = "MST_NO_SPELLS",
    leaves_corpse = true,
    shout_id = "S_SILENT",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 6,
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
    shape_id = "MON_SHAPE_SNAKE",
    tile = {
        id = "TILEP_MONS_WORM",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_WORM",
    population = {
        -- Source line: 82
        {
            source_order = 17,
            min_depth = 2,
            max_depth = 5,
            rarity = 500,
            curve = curves.FALL,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
