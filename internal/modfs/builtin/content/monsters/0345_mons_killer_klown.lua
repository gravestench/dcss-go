-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:1927

local categories = require("constants.catalog")

local definition = {
    id = "MONS_KILLER_KLOWN",
    status = "defined",
    name = "Killer Klown",
    glyph = 112,
    colour_id = "ETC_RANDOM",
    flags = {
        "M_SEE_INVIS",
        "M_SPEAKS",
        "M_WARM_BLOOD",
        "M_NO_POLY_TO",
        "M_NO_GEN_DERIVED",
    },
    xp_modifier = 17,
    genus_id = "MONS_HUMAN",
    species_id = "MONS_KILLER_KLOWN",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 160,
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 30,
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
    hd = 20,
    average_hp_10x = 1500,
    ac = 10,
    ev = 15,
    spellbook_id = "MST_KILLER_KLOWN",
    leaves_corpse = true,
    shout_id = "S_SHOUT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 13,
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
    size_id = "SIZE_MEDIUM",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_KILLER_KLOWN",
        variation_id = "TVARY_RANDOM",
    },
    corpse_tile_id = "TILE_CORPSE_KILLER_KLOWN",
}

register.definition(categories.MONSTERS, definition)

return definition
