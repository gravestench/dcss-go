-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:4383

local categories = require("constants.catalog")
local curves = require("constants.population_curves")

local definition = {
    id = "MONS_BALL_PYTHON",
    status = "defined",
    name = "ball python",
    glyph = 83,
    colour_id = "GREEN",
    flags = {
        "M_COLD_BLOOD",
    },
    xp_modifier = 13,
    genus_id = "MONS_SNAKE",
    species_id = "MONS_BALL_PYTHON",
    holiness = {
        "MH_NATURAL",
    },
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_PLAIN",
            damage = 3,
        },
        {
            type_id = "AT_CONSTRICT",
            flavour_id = "AF_CRUSH",
            damage = 1,
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
    average_hp_10x = 35,
    ev = 11,
    spellbook_id = "MST_NO_SPELLS",
    leaves_corpse = true,
    shout_id = "S_HISS",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_AMPHIBIOUS",
    speed = 12,
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
    size_id = "SIZE_MEDIUM",
    shape_id = "MON_SHAPE_SNAKE",
    tile = {
        id = "TILEP_MONS_BALL_PYTHON",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_BALL_PYTHON",
    population = {
        -- Source line: 67
        {
            source_order = 4,
            min_depth = 1,
            max_depth = 4,
            rarity = 1000,
            curve = curves.FLAT,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
