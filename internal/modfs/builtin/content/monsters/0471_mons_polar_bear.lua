-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:1249

local categories = require("constants.catalog")

local definition = {
    id = "MONS_POLAR_BEAR",
    status = "defined",
    name = "polar bear",
    glyph = 104,
    colour_id = "LIGHTBLUE",
    flags = {
        "M_WARM_BLOOD",
    },
    resistances = {
        {
            id = "MR_RES_COLD",
            level = 1,
        },
    },
    xp_modifier = 12,
    genus_id = "MONS_BEAR",
    species_id = "MONS_POLAR_BEAR",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 20,
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_PLAIN",
            damage = 20,
        },
        {
            type_id = "AT_CLAW",
            flavour_id = "AF_PLAIN",
            damage = 5,
        },
        {
            type_id = "AT_CLAW",
            flavour_id = "AF_PLAIN",
            damage = 5,
        },
        {
            type_id = "AT_NONE",
            flavour_id = "AF_PLAIN",
            damage = 0,
        },
    },
    hd = 7,
    average_hp_10x = 455,
    ac = 7,
    ev = 8,
    spellbook_id = "MST_BEAR",
    leaves_corpse = true,
    shout_id = "S_GROWL",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_AMPHIBIOUS",
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
    item_use_id = "MONUSE_NOTHING",
    size_id = "SIZE_LARGE",
    shape_id = "MON_SHAPE_QUADRUPED_TAILLESS",
    tile = {
        id = "TILEP_MONS_POLAR_BEAR",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_POLAR_BEAR",
}

register.definition(categories.MONSTERS, definition)

return definition
