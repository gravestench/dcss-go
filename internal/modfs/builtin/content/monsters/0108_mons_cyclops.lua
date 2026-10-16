-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:2929

local categories = require("constants.catalog")
local curves = require("constants.population_curves")

local definition = {
    id = "MONS_CYCLOPS",
    status = "defined",
    name = "cyclops",
    glyph = 67,
    colour_id = "YELLOW",
    flags = {
        "M_WARM_BLOOD",
        "M_SPEAKS",
    },
    xp_modifier = 14,
    genus_id = "MONS_GIANT",
    species_id = "MONS_CYCLOPS",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 40,
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 35,
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
    ac = 5,
    ev = 3,
    spellbook_id = "MST_NO_SPELLS",
    leaves_corpse = true,
    shout_id = "S_SHOUT",
    intelligence_id = "I_HUMAN",
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
    item_use_id = "MONUSE_STARTING_EQUIPMENT",
    size_id = "SIZE_GIANT",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_CYCLOPS",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_CYCLOPS",
    population = {
        -- Source line: 131
        {
            source_order = 62,
            min_depth = 11,
            max_depth = 21,
            rarity = 825,
            curve = curves.SEMI,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
