-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:3143

local categories = require("constants.catalog")

local definition = {
    id = "MONS_QUICKSILVER_DRAGON",
    status = "defined",
    name = "quicksilver dragon",
    glyph = 68,
    colour_id = "LIGHTCYAN",
    flags = {
        "M_SEE_INVIS",
        "M_WARM_BLOOD",
        "M_FLIES",
    },
    xp_modifier = 14,
    genus_id = "MONS_DRAGON",
    species_id = "MONS_QUICKSILVER_DRAGON",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 140,
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_PLAIN",
            damage = 25,
        },
        {
            type_id = "AT_CLAW",
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
    },
    hd = 16,
    average_hp_10x = 880,
    ac = 10,
    ev = 15,
    spellbook_id = "MST_QUICKSILVER_DRAGON",
    leaves_corpse = true,
    shout_id = "S_LOUD_ROAR",
    intelligence_id = "I_ANIMAL",
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
    item_use_id = "MONUSE_NOTHING",
    size_id = "SIZE_GIANT",
    shape_id = "MON_SHAPE_QUADRUPED_WINGED",
    tile = {
        id = "TILEP_MONS_QUICKSILVER_DRAGON",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_QUICKSILVER_DRAGON",
}

register.definition(categories.MONSTERS, definition)

return definition
