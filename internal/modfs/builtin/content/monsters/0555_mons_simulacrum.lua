-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:5092

local categories = require("constants.catalog")
local curves = require("constants.population_curves")

local definition = {
    id = "MONS_SIMULACRUM",
    status = "defined",
    name = "simulacrum",
    glyph = 90,
    colour_id = "LIGHTBLUE",
    flags = {
        "M_NO_REGEN",
    },
    resistances = {
        {
            id = "MR_RES_FIRE",
            level = -1,
        },
        {
            id = "MR_RES_COLD",
            level = 3,
        },
    },
    xp_modifier = 9,
    genus_id = "MONS_SIMULACRUM",
    species_id = "MONS_SIMULACRUM",
    holiness = {
        "MH_UNDEAD",
    },
    willpower = -1,
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 6,
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
    hd = 2,
    average_hp_10x = 110,
    ac = 10,
    ev = 4,
    spellbook_id = "MST_NO_SPELLS",
    shout_id = "S_SILENT",
    intelligence_id = "I_BRAINLESS",
    habitat_id = "HT_LAND",
    speed = 7,
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
    shape_id = "MON_SHAPE_MISC",
    tile = {
        id = "TILEP_MONS_SIMULACRUM_SMALL",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
    population = {
        -- Source line: 150
        {
            source_order = 81,
            min_depth = 14,
            max_depth = 22,
            rarity = 270,
            curve = curves.SEMI,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
