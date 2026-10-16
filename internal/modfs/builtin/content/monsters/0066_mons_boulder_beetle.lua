-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:2886

local categories = require("constants.catalog")
local curves = require("constants.population_curves")

local definition = {
    id = "MONS_BOULDER_BEETLE",
    status = "defined",
    name = "boulder beetle",
    glyph = 66,
    colour_id = "LIGHTGREY",
    flags = {
        "M_NO_SKELETON",
        "M_WEB_IMMUNE",
    },
    resistances = {
        {
            id = "MR_RES_POISON",
            level = -1,
        },
    },
    xp_modifier = 12,
    genus_id = "MONS_BOULDER_BEETLE",
    species_id = "MONS_BOULDER_BEETLE",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 40,
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_PLAIN",
            damage = 32,
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
    hd = 12,
    average_hp_10x = 765,
    ac = 20,
    ev = 2,
    spellbook_id = "MST_BOULDER_BEETLE",
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
    shape_id = "MON_SHAPE_INSECT",
    tile = {
        id = "TILEP_MONS_BOULDER_BEETLE",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_BOULDER_BEETLE",
    population = {
        -- Source line: 135
        {
            source_order = 66,
            min_depth = 11,
            max_depth = 23,
            rarity = 540,
            curve = curves.SEMI,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
