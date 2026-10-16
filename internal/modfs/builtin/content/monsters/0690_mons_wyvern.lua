-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:1467

local categories = require("constants.catalog")
local curves = require("constants.population_curves")

local definition = {
    id = "MONS_WYVERN",
    status = "defined",
    name = "wyvern",
    glyph = 108,
    colour_id = "LIGHTGREEN",
    flags = {
        "M_WARM_BLOOD",
        "M_FLIES",
    },
    xp_modifier = 15,
    genus_id = "MONS_WYVERN",
    species_id = "MONS_WYVERN",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 20,
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_PLAIN",
            damage = 20,
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
    ac = 5,
    ev = 10,
    spellbook_id = "MST_NO_SPELLS",
    leaves_corpse = true,
    shout_id = "S_HISS",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 15,
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
    shape_id = "MON_SHAPE_QUADRUPED_WINGED",
    tile = {
        id = "TILEP_MONS_WYVERN",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_WYVERN",
    population = {
        -- Source line: 116
        {
            source_order = 47,
            min_depth = 7,
            max_depth = 11,
            rarity = 350,
            curve = curves.PEAK,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
