-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:1744

local categories = require("constants.catalog")
local curves = require("constants.population_curves")

local definition = {
    id = "MONS_ORC_HIGH_PRIEST",
    status = "defined",
    name = "orc high priest",
    glyph = 111,
    colour_id = "LIGHTGREEN",
    flags = {
        "M_SPEAKS",
        "M_WARM_BLOOD",
    },
    xp_modifier = 10,
    genus_id = "MONS_ORC",
    species_id = "MONS_ORC",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 60,
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 7,
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
    hd = 11,
    average_hp_10x = 550,
    ac = 1,
    ev = 12,
    spellbook_id = "MST_ORC_HIGH_PRIEST",
    leaves_corpse = true,
    shout_id = "S_SHOUT",
    intelligence_id = "I_HUMAN",
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
    item_use_id = "MONUSE_WEAPONS_ARMOUR",
    size_id = "SIZE_MEDIUM",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_ORC_HIGH_PRIEST",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
    population = {
        -- Source line: 171
        {
            source_order = 102,
            min_depth = 19,
            max_depth = 25,
            rarity = 35,
            curve = curves.PEAK,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
