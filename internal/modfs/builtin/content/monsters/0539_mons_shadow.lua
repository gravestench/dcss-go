-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:4686

local categories = require("constants.catalog")
local curves = require("constants.population_curves")

local definition = {
    id = "MONS_SHADOW",
    status = "defined",
    name = "shadow",
    glyph = 87,
    colour_id = "MAGENTA",
    flags = {
        "M_SEE_INVIS",
        "M_INSUBSTANTIAL",
        "M_FLIES",
    },
    resistances = {
        {
            id = "MR_RES_COLD",
            level = 3,
        },
    },
    xp_modifier = 18,
    genus_id = "MONS_WRAITH",
    species_id = "MONS_SHADOW",
    holiness = {
        "MH_UNDEAD",
    },
    willpower = 40,
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_SHADOWSTAB",
            damage = 14,
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
    average_hp_10x = 240,
    ac = 7,
    ev = 10,
    spellbook_id = "MST_SHADOW",
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
    item_use_id = "MONUSE_OPEN_DOORS",
    size_id = "SIZE_SMALL",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_SHADOW",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
    population = {
        -- Source line: 120
        {
            source_order = 51,
            min_depth = 9,
            max_depth = 13,
            rarity = 350,
            curve = curves.PEAK,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
