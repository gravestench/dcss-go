-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:4017

local categories = require("constants.catalog")

local definition = {
    id = "MONS_TWO_HEADED_OGRE",
    status = "defined",
    name = "two-headed ogre",
    glyph = 79,
    colour_id = "LIGHTRED",
    flags = {
        "M_WARM_BLOOD",
        "M_TWO_WEAPONS",
        "M_SPEAKS",
    },
    xp_modifier = 15,
    genus_id = "MONS_OGRE",
    species_id = "MONS_TWO_HEADED_OGRE",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 40,
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 24,
        },
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 18,
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
    ac = 3,
    ev = 6,
    spellbook_id = "MST_NO_SPELLS",
    leaves_corpse = true,
    shout_id = "S_SHOUT2",
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
    item_use_id = "MONUSE_STARTING_EQUIPMENT",
    size_id = "SIZE_LARGE",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_TWO_HEADED_OGRE",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_TWO_HEADED_OGRE",
}

register.definition(categories.MONSTERS, definition)

return definition
