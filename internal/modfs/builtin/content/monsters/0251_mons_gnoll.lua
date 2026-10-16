-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:1012

local categories = require("constants.catalog")
local curves = require("constants.population_curves")

local definition = {
    id = "MONS_GNOLL",
    status = "defined",
    name = "gnoll",
    glyph = 103,
    colour_id = "YELLOW",
    flags = {
        "M_WARM_BLOOD",
        "M_SPEAKS",
    },
    xp_modifier = 10,
    genus_id = "MONS_GNOLL",
    species_id = "MONS_GNOLL",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 10,
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
    average_hp_10x = 130,
    ac = 2,
    ev = 9,
    spellbook_id = "MST_NO_SPELLS",
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
        id = "TILEP_MONS_GNOLL",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_GNOLL",
    population = {
        -- Source line: 79
        {
            source_order = 16,
            min_depth = 1,
            max_depth = 8,
            rarity = 200,
            curve = curves.PEAK,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
