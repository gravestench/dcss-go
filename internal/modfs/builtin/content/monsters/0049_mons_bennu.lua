-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:407

local categories = require("constants.catalog")

local definition = {
    id = "MONS_BENNU",
    status = "defined",
    name = "bennu",
    glyph = 98,
    colour_id = "YELLOW",
    flags = {
        "M_SEE_INVIS",
        "M_WARM_BLOOD",
        "M_FAST_REGEN",
        "M_NO_POLY_TO",
        "M_SPEAKS",
        "M_FLIES",
    },
    resistances = {
        {
            id = "MR_RES_FIRE",
            level = 3,
        },
        {
            id = "MR_RES_NEG",
            level = 3,
        },
        {
            id = "MR_RES_POISON",
            level = 1,
        },
        {
            id = "MR_RES_MIASMA",
            level = 1,
        },
    },
    xp_modifier = 6,
    genus_id = "MONS_BENNU",
    species_id = "MONS_BENNU",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 140,
    attacks = {
        {
            type_id = "AT_PECK",
            flavour_id = "AF_HOLY",
            damage = 27,
        },
        {
            type_id = "AT_CLAW",
            flavour_id = "AF_PLAIN",
            damage = 24,
        },
        {
            type_id = "AT_CLAW",
            flavour_id = "AF_PLAIN",
            damage = 24,
        },
        {
            type_id = "AT_NONE",
            flavour_id = "AF_PLAIN",
            damage = 0,
        },
    },
    hd = 14,
    average_hp_10x = 770,
    ac = 6,
    ev = 16,
    spellbook_id = "MST_NO_SPELLS",
    shout_id = "S_SCREECH",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 16,
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
    size_id = "SIZE_MEDIUM",
    shape_id = "MON_SHAPE_BIRD",
    tile = {
        id = "TILEP_MONS_BENNU",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
