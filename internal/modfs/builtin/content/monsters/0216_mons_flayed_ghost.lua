-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:4658

local categories = require("constants.catalog")
local curves = require("constants.population_curves")

local definition = {
    id = "MONS_FLAYED_GHOST",
    status = "defined",
    name = "flayed ghost",
    glyph = 87,
    colour_id = "RED",
    flags = {
        "M_INSUBSTANTIAL",
        "M_SPEAKS",
        "M_FLIES",
    },
    xp_modifier = 10,
    genus_id = "MONS_PHANTOM",
    species_id = "MONS_FLAYED_GHOST",
    holiness = {
        "MH_UNDEAD",
    },
    willpower = 60,
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 30,
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
    average_hp_10x = 605,
    ev = 14,
    spellbook_id = "MST_FLAYED_GHOST",
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
        id = "TILEP_MONS_FLAYED_GHOST",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
    population = {
        -- Source line: 170
        {
            source_order = 101,
            min_depth = 18,
            max_depth = 28,
            rarity = 180,
            curve = curves.PEAK,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
