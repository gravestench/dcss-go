-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:475

local categories = require("constants.catalog")
local curves = require("constants.population_curves")

local definition = {
    id = "MONS_YAKTAUR",
    status = "defined",
    name = "yaktaur",
    glyph = 99,
    colour_id = "RED",
    flags = {
        "M_WARM_BLOOD",
        "M_ARCHER",
        "M_SPEAKS",
    },
    xp_modifier = 9,
    genus_id = "MONS_YAKTAUR",
    species_id = "MONS_YAKTAUR",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 40,
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
    hd = 8,
    average_hp_10x = 440,
    ac = 4,
    ev = 4,
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
    size_id = "SIZE_LARGE",
    shape_id = "MON_SHAPE_CENTAUR",
    tile = {
        id = "TILEP_MONS_YAKTAUR",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_YAKTAUR",
    population = {
        -- Source line: 153
        {
            source_order = 84,
            min_depth = 15,
            max_depth = 20,
            rarity = 335,
            curve = curves.SEMI,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
