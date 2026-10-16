-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:4410

local categories = require("constants.catalog")
local curves = require("constants.population_curves")

local definition = {
    id = "MONS_WATER_MOCCASIN",
    status = "defined",
    name = "water moccasin",
    glyph = 83,
    colour_id = "BROWN",
    flags = {
        "M_COLD_BLOOD",
    },
    resistances = {
        {
            id = "MR_RES_POISON",
            level = 1,
        },
    },
    xp_modifier = 11,
    genus_id = "MONS_SNAKE",
    species_id = "MONS_WATER_MOCCASIN",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 20,
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_POISON",
            damage = 10,
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
    ac = 2,
    ev = 15,
    spellbook_id = "MST_NO_SPELLS",
    leaves_corpse = true,
    shout_id = "S_HISS",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_AMPHIBIOUS",
    speed = 14,
    energy = {
        move = 10,
        swim = 6,
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
        id = "TILEP_MONS_WATER_MOCCASIN",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_WATER_MOCCASIN",
    population = {
        -- Source line: 104
        {
            source_order = 36,
            min_depth = 5,
            max_depth = 9,
            rarity = 400,
            curve = curves.PEAK,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
