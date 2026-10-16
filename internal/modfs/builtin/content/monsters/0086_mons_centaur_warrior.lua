-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:462

local categories = require("constants.catalog")
local curves = require("constants.population_curves")

local definition = {
    id = "MONS_CENTAUR_WARRIOR",
    status = "defined",
    name = "centaur warrior",
    glyph = 99,
    colour_id = "YELLOW",
    flags = {
        "M_WARM_BLOOD",
        "M_FIGHTER",
        "M_ARCHER",
        "M_SPEAKS",
    },
    xp_modifier = 12,
    genus_id = "MONS_CENTAUR",
    species_id = "MONS_CENTAUR",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 40,
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 16,
        },
        {
            type_id = "AT_KICK",
            flavour_id = "AF_PLAIN",
            damage = 5,
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
    hd = 10,
    average_hp_10x = 550,
    ac = 4,
    ev = 8,
    spellbook_id = "MST_NO_SPELLS",
    leaves_corpse = true,
    shout_id = "S_SHOUT",
    intelligence_id = "I_HUMAN",
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
    item_use_id = "MONUSE_WEAPONS_ARMOUR",
    size_id = "SIZE_LARGE",
    shape_id = "MON_SHAPE_CENTAUR",
    tile = {
        id = "TILEP_MONS_CENTAUR_WARRIOR",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
    population = {
        -- Source line: 141
        {
            source_order = 72,
            min_depth = 13,
            max_depth = 17,
            rarity = 925,
            curve = curves.FLAT,
        },
        -- Source line: 142
        {
            source_order = 73,
            min_depth = 18,
            max_depth = 23,
            rarity = 925,
            curve = curves.FALL,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
