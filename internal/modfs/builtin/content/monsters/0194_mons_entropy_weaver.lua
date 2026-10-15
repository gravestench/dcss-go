-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:2872

local categories = require("constants.catalog")

local definition = {
    id = "MONS_ENTROPY_WEAVER",
    status = "defined",
    name = "entropy weaver",
    glyph = 66,
    colour_id = "LIGHTCYAN",
    flags = {
        "M_WARM_BLOOD",
        "M_NO_SKELETON",
        "M_FIGHTER",
        "M_SEE_INVIS",
        "M_SPEAKS",
        "M_WEB_IMMUNE",
    },
    xp_modifier = 10,
    genus_id = "MONS_ENTROPY_WEAVER",
    species_id = "MONS_ENTROPY_WEAVER",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 60,
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 17,
        },
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 17,
        },
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 17,
        },
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 17,
        },
    },
    hd = 13,
    average_hp_10x = 715,
    ac = 7,
    ev = 13,
    spellbook_id = "MST_ENTROPY_WEAVER",
    leaves_corpse = true,
    shout_id = "S_SHOUT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 12,
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
    item_use_id = "MONUSE_OPEN_DOORS",
    size_id = "SIZE_MEDIUM",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_ENTROPY_WEAVER",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_ENTROPY_WEAVER",
}

register.definition(categories.MONSTERS, definition)

return definition
