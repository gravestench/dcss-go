-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:4969

local categories = require("constants.catalog")
local curves = require("constants.population_curves")

local definition = {
    id = "MONS_CATOBLEPAS",
    status = "defined",
    name = "catoblepas",
    glyph = 89,
    colour_id = "MAGENTA",
    flags = {
        "M_WARM_BLOOD",
    },
    resistances = {
        {
            id = "MR_RES_PETRIFY",
            level = 1,
        },
    },
    xp_modifier = 8,
    genus_id = "MONS_YAK",
    species_id = "MONS_CATOBLEPAS",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 100,
    attacks = {
        {
            type_id = "AT_GORE",
            flavour_id = "AF_PLAIN",
            damage = 36,
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
    hd = 14,
    average_hp_10x = 770,
    ac = 10,
    ev = 2,
    spellbook_id = "MST_CATOBLEPAS",
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
        id = "TILEP_MONS_CATOBLEPAS",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_CATOBLEPAS",
    population = {
        -- Source line: 147
        {
            source_order = 78,
            min_depth = 13,
            max_depth = 27,
            rarity = 89,
            curve = curves.FALL,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
