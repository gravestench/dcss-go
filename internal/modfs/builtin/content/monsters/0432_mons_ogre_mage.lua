-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:4030

local categories = require("constants.catalog")
local curves = require("constants.population_curves")

local definition = {
    id = "MONS_OGRE_MAGE",
    status = "defined",
    name = "ogre mage",
    glyph = 79,
    colour_id = "MAGENTA",
    flags = {
        "M_SEE_INVIS",
        "M_WARM_BLOOD",
        "M_SPEAKS",
    },
    xp_modifier = 16,
    genus_id = "MONS_OGRE",
    species_id = "MONS_OGRE",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 80,
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 16,
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
    hd = 10,
    average_hp_10x = 550,
    ac = 1,
    ev = 7,
    spellbook_id = "MST_OGRE_MAGE",
    leaves_corpse = true,
    shout_id = "S_SHOUT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    energy = {
        move = 10,
        swim = 10,
        attack = 15,
        missile = 10,
        spell = 10,
        special = 10,
        item = 10,
        pickup_percent = 100,
    },
    item_use_id = "MONUSE_WEAPONS_ARMOUR",
    size_id = "SIZE_LARGE",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_OGRE_MAGE",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
    population = {
        -- Source line: 155
        {
            source_order = 86,
            min_depth = 15,
            max_depth = 25,
            rarity = 315,
            curve = curves.FALL,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
