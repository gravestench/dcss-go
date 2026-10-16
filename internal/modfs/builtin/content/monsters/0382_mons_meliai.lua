-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:2593

local categories = require("constants.catalog")
local curves = require("constants.population_curves")

local definition = {
    id = "MONS_MELIAI",
    status = "defined",
    name = "meliai",
    glyph = 121,
    colour_id = "GREEN",
    flags = {
        "M_NO_SKELETON",
        "M_FLIES",
        "M_WEB_IMMUNE",
    },
    resistances = {
        {
            id = "MR_RES_POISON",
            level = -1,
        },
    },
    xp_modifier = 6,
    genus_id = "MONS_KILLER_BEE",
    species_id = "MONS_MELIAI",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 20,
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 14,
        },
        {
            type_id = "AT_STING",
            flavour_id = "AF_POISON",
            damage = 12,
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
    hd = 7,
    average_hp_10x = 245,
    ac = 2,
    ev = 14,
    spellbook_id = "MST_MELIAI",
    leaves_corpse = true,
    shout_id = "S_BUZZ",
    intelligence_id = "I_HUMAN",
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
    item_use_id = "MONUSE_WEAPONS_ARMOUR",
    size_id = "SIZE_SMALL",
    shape_id = "MON_SHAPE_INSECT_WINGED",
    tile = {
        id = "TILEP_MONS_MELIAI",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_MELIAI",
    population = {
        -- Source line: 138
        {
            source_order = 69,
            min_depth = 13,
            max_depth = 20,
            rarity = 150,
            curve = curves.SEMI,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
