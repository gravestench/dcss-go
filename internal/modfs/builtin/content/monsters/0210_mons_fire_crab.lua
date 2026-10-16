-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:2239

local categories = require("constants.catalog")
local curves = require("constants.population_curves")

local definition = {
    id = "MONS_FIRE_CRAB",
    status = "defined",
    name = "fire crab",
    glyph = 116,
    colour_id = "LIGHTRED",
    flags = {
        "M_NO_SKELETON",
    },
    resistances = {
        {
            id = "MR_RES_POISON",
            level = -1,
        },
        {
            id = "MR_RES_FIRE",
            level = 3,
        },
    },
    xp_modifier = 25,
    genus_id = "MONS_CRAB",
    species_id = "MONS_FIRE_CRAB",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 40,
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_FIRE",
            damage = 15,
        },
        {
            type_id = "AT_CLAW",
            flavour_id = "AF_FIRE",
            damage = 15,
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
    hd = 8,
    average_hp_10x = 520,
    ac = 9,
    ev = 6,
    spellbook_id = "MST_FIRE_CRAB",
    leaves_corpse = true,
    shout_id = "S_SILENT",
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
    size_id = "SIZE_SMALL",
    shape_id = "MON_SHAPE_QUADRUPED",
    tile = {
        id = "TILEP_MONS_FIRE_CRAB",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_FIRE_CRAB",
    population = {
        -- Source line: 166
        {
            source_order = 97,
            min_depth = 17,
            max_depth = 25,
            rarity = 89,
            curve = curves.PEAK,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
