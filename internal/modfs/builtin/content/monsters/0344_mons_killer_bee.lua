-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:2541

local categories = require("constants.catalog")
local curves = require("constants.population_curves")

local definition = {
    id = "MONS_KILLER_BEE",
    status = "defined",
    name = "killer bee",
    glyph = 121,
    colour_id = "BROWN",
    flags = {
        "M_NO_SKELETON",
        "M_FLIES",
    },
    resistances = {
        {
            id = "MR_RES_POISON",
            level = -1,
        },
    },
    xp_modifier = 11,
    genus_id = "MONS_KILLER_BEE",
    species_id = "MONS_KILLER_BEE",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 10,
    attacks = {
        {
            type_id = "AT_STING",
            flavour_id = "AF_POISON",
            damage = 10,
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
    hd = 3,
    average_hp_10x = 165,
    ac = 2,
    ev = 18,
    spellbook_id = "MST_NO_SPELLS",
    leaves_corpse = true,
    shout_id = "S_BUZZ",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 20,
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
    size_id = "SIZE_TINY",
    shape_id = "MON_SHAPE_INSECT_WINGED",
    tile = {
        id = "TILEP_MONS_KILLER_BEE",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_KILLER_BEE",
    population = {
        -- Source line: 114
        {
            source_order = 45,
            min_depth = 7,
            max_depth = 11,
            rarity = 500,
            curve = curves.PEAK,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
