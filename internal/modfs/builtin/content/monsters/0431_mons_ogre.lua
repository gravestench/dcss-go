-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:4002

local categories = require("constants.catalog")
local curves = require("constants.population_curves")

local definition = {
    id = "MONS_OGRE",
    status = "defined",
    name = "ogre",
    glyph = 79,
    colour_id = "BROWN",
    flags = {
        "M_WARM_BLOOD",
        "M_SPEAKS",
    },
    xp_modifier = 9,
    genus_id = "MONS_OGRE",
    species_id = "MONS_OGRE",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 20,
    attacks = {
        {
            type_id = "AT_HIT",
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
    ac = 1,
    ev = 6,
    spellbook_id = "MST_NO_SPELLS",
    leaves_corpse = true,
    shout_id = "S_SHOUT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    energy = {
        move = 10,
        swim = 10,
        attack = 15,
        missile = 10,
        spell = 10,
        special = 10,
        item = 10,
        pickup_percent = 100,
    },
    item_use_id = "MONUSE_STARTING_EQUIPMENT",
    size_id = "SIZE_LARGE",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_OGRE",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_OGRE",
    population = {
        -- Source line: 90
        {
            source_order = 23,
            min_depth = 4,
            max_depth = 7,
            rarity = 500,
            curve = curves.PEAK,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
