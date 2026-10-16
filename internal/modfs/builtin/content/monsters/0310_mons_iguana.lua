-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:1441

local categories = require("constants.catalog")
local curves = require("constants.population_curves")

local definition = {
    id = "MONS_IGUANA",
    status = "defined",
    name = "iguana",
    glyph = 108,
    colour_id = "BLUE",
    flags = {
        "M_COLD_BLOOD",
    },
    xp_modifier = 13,
    genus_id = "MONS_GIANT_LIZARD",
    species_id = "MONS_IGUANA",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 10,
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_PLAIN",
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
        {
            type_id = "AT_NONE",
            flavour_id = "AF_PLAIN",
            damage = 0,
        },
    },
    hd = 3,
    average_hp_10x = 165,
    ac = 5,
    ev = 9,
    spellbook_id = "MST_NO_SPELLS",
    leaves_corpse = true,
    shout_id = "S_HISS",
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
        id = "TILEP_MONS_IGUANA",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_IGUANA",
    population = {
        -- Source line: 91
        {
            source_order = 24,
            min_depth = 4,
            max_depth = 7,
            rarity = 1000,
            curve = curves.PEAK,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
