-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:4791

local categories = require("constants.catalog")
local curves = require("constants.population_curves")

local definition = {
    id = "MONS_PHANTASMAL_WARRIOR",
    status = "defined",
    name = "phantasmal warrior",
    glyph = 87,
    colour_id = "LIGHTGREEN",
    flags = {
        "M_FIGHTER",
        "M_SEE_INVIS",
        "M_INSUBSTANTIAL",
        "M_FLIES",
    },
    resistances = {
        {
            id = "MR_RES_COLD",
            level = 1,
        },
    },
    xp_modifier = 13,
    genus_id = "MONS_WRAITH",
    species_id = "MONS_PHANTASMAL_WARRIOR",
    holiness = {
        "MH_UNDEAD",
    },
    willpower = 80,
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_VULN",
            damage = 39,
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
    hd = 9,
    average_hp_10x = 495,
    ac = 12,
    ev = 10,
    spellbook_id = "MST_PHANTASMAL_WARRIOR",
    shout_id = "S_SILENT",
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
    item_use_id = "MONUSE_OPEN_DOORS",
    size_id = "SIZE_MEDIUM",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_PHANTASMAL_WARRIOR",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
    population = {
        -- Source line: 184
        {
            source_order = 115,
            min_depth = 23,
            max_depth = 31,
            rarity = 89,
            curve = curves.PEAK,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
