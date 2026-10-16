-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:3337

local categories = require("constants.catalog")
local curves = require("constants.population_curves")

local definition = {
    id = "MONS_BULLFROG",
    status = "defined",
    name = "bullfrog",
    glyph = 70,
    colour_id = "GREEN",
    flags = {
        "M_COLD_BLOOD",
    },
    xp_modifier = 10,
    genus_id = "MONS_FROG",
    species_id = "MONS_BULLFROG",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 20,
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 9,
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
    hd = 4,
    average_hp_10x = 220,
    ev = 12,
    spellbook_id = "MST_NO_SPELLS",
    leaves_corpse = true,
    shout_id = "S_CROAK",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_AMPHIBIOUS",
    speed = 15,
    energy = {
        move = 10,
        swim = 6,
        attack = 10,
        missile = 10,
        spell = 10,
        special = 10,
        item = 10,
        pickup_percent = 100,
    },
    item_use_id = "MONUSE_NOTHING",
    size_id = "SIZE_MEDIUM",
    shape_id = "MON_SHAPE_QUADRUPED_TAILLESS",
    tile = {
        id = "TILEP_MONS_BULLFROG",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_BULLFROG",
    population = {
        -- Source line: 109
        {
            source_order = 40,
            min_depth = 6,
            max_depth = 9,
            rarity = 1000,
            curve = curves.PEAK,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
