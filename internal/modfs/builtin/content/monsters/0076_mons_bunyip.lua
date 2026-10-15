-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:2527

local categories = require("constants.catalog")

local definition = {
    id = "MONS_BUNYIP",
    status = "defined",
    name = "bunyip",
    glyph = 120,
    colour_id = "YELLOW",
    flags = {
        "M_WARM_BLOOD",
    },
    resistances = {
        {
            id = "MR_RES_POISON",
            level = 1,
        },
    },
    xp_modifier = 7,
    genus_id = "MONS_BUNYIP",
    species_id = "MONS_BUNYIP",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 60,
    attacks = {
        {
            type_id = "AT_CLAW",
            flavour_id = "AF_PLAIN",
            damage = 40,
        },
        {
            type_id = "AT_CLAW",
            flavour_id = "AF_PLAIN",
            damage = 40,
        },
        {
            type_id = "AT_CLAW",
            flavour_id = "AF_PLAIN",
            damage = 40,
        },
        {
            type_id = "AT_NONE",
            flavour_id = "AF_PLAIN",
            damage = 0,
        },
    },
    hd = 12,
    average_hp_10x = 800,
    ac = 6,
    ev = 10,
    spellbook_id = "MST_BUNYIP",
    leaves_corpse = true,
    shout_id = "S_SCREAM",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_AMPHIBIOUS",
    speed = 15,
    energy = {
        move = 10,
        swim = 10,
        attack = 45,
        missile = 10,
        spell = 10,
        special = 10,
        item = 10,
        pickup_percent = 100,
    },
    item_use_id = "MONUSE_NOTHING",
    size_id = "SIZE_LARGE",
    shape_id = "MON_SHAPE_QUADRUPED",
    tile = {
        id = "TILEP_MONS_BUNYIP",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_BUNYIP",
}

register.definition(categories.MONSTERS, definition)

return definition
