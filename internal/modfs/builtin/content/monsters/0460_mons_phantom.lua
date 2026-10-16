-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:4645

local categories = require("constants.catalog")
local curves = require("constants.population_curves")

local definition = {
    id = "MONS_PHANTOM",
    status = "defined",
    name = "phantom",
    glyph = 87,
    colour_id = "BLUE",
    flags = {
        "M_INSUBSTANTIAL",
        "M_FLIES",
    },
    resistances = {
        {
            id = "MR_RES_COLD",
            level = 2,
        },
    },
    xp_modifier = 7,
    genus_id = "MONS_PHANTOM",
    species_id = "MONS_PHANTOM",
    holiness = {
        "MH_UNDEAD",
    },
    willpower = 40,
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_BLINK_WITH",
            damage = 8,
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
    hd = 6,
    average_hp_10x = 270,
    ac = 3,
    ev = 13,
    spellbook_id = "MST_NO_SPELLS",
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
        id = "TILEP_MONS_PHANTOM",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
    population = {
        -- Source line: 92
        {
            source_order = 25,
            min_depth = 4,
            max_depth = 7,
            rarity = 350,
            curve = curves.PEAK,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
