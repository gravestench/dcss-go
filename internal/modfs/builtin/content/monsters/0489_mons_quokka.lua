-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:2006

local categories = require("constants.catalog")
local curves = require("constants.population_curves")

local definition = {
    id = "MONS_QUOKKA",
    status = "defined",
    name = "quokka",
    glyph = 114,
    colour_id = "WHITE",
    flags = {
        "M_WARM_BLOOD",
    },
    xp_modifier = 10,
    genus_id = "MONS_QUOKKA",
    species_id = "MONS_QUOKKA",
    holiness = {
        "MH_NATURAL",
    },
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_PLAIN",
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
    hd = 1,
    average_hp_10x = 55,
    ac = 2,
    ev = 13,
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
    size_id = "SIZE_LITTLE",
    shape_id = "MON_SHAPE_QUADRUPED",
    tile = {
        id = "TILEP_MONS_QUOKKA",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_QUOKKA",
    population = {
        -- Source line: 74
        {
            source_order = 11,
            min_depth = 1,
            max_depth = 3,
            rarity = 500,
            curve = curves.FLAT,
        },
        -- Source line: 77
        {
            source_order = 14,
            min_depth = 4,
            max_depth = 5,
            rarity = 500,
            curve = curves.FALL,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
