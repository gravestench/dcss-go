-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:3497

local categories = require("constants.catalog")
local curves = require("constants.population_curves")

local definition = {
    id = "MONS_MANTICORE",
    status = "defined",
    name = "manticore",
    glyph = 72,
    colour_id = "RED",
    flags = {
        "M_WARM_BLOOD",
        "M_FLIES",
    },
    xp_modifier = 10,
    genus_id = "MONS_MANTICORE",
    species_id = "MONS_MANTICORE",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 40,
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_PLAIN",
            damage = 26,
        },
        {
            type_id = "AT_CLAW",
            flavour_id = "AF_PLAIN",
            damage = 14,
        },
        {
            type_id = "AT_CLAW",
            flavour_id = "AF_PLAIN",
            damage = 14,
        },
        {
            type_id = "AT_NONE",
            flavour_id = "AF_PLAIN",
            damage = 0,
        },
    },
    hd = 9,
    average_hp_10x = 495,
    ac = 5,
    ev = 7,
    spellbook_id = "MST_MANTICORE",
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
    size_id = "SIZE_LARGE",
    shape_id = "MON_SHAPE_QUADRUPED",
    tile = {
        id = "TILEP_MONS_MANTICORE",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_MANTICORE",
    population = {
        -- Source line: 130
        {
            source_order = 61,
            min_depth = 11,
            max_depth = 21,
            rarity = 520,
            curve = curves.SEMI,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
