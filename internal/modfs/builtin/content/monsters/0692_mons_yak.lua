-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:4943

local categories = require("constants.catalog")
local curves = require("constants.population_curves")

local definition = {
    id = "MONS_YAK",
    status = "defined",
    name = "yak",
    glyph = 89,
    colour_id = "BROWN",
    flags = {
        "M_WARM_BLOOD",
        "M_HERD",
    },
    xp_modifier = 9,
    genus_id = "MONS_YAK",
    species_id = "MONS_YAK",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 20,
    attacks = {
        {
            type_id = "AT_GORE",
            flavour_id = "AF_PLAIN",
            damage = 18,
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
    ac = 4,
    ev = 7,
    spellbook_id = "MST_NO_SPELLS",
    leaves_corpse = true,
    shout_id = "S_BELLOW",
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
    size_id = "SIZE_LARGE",
    shape_id = "MON_SHAPE_QUADRUPED",
    tile = {
        id = "TILEP_MONS_YAK",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_YAK",
    population = {
        -- Source line: 117
        {
            source_order = 48,
            min_depth = 8,
            max_depth = 12,
            rarity = 800,
            curve = curves.PEAK,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
