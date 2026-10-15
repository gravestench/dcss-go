-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:5728

local categories = require("constants.catalog")

local definition = {
    id = "MONS_ORANGE_DEMON",
    status = "defined",
    name = "orange demon",
    glyph = 52,
    colour_id = "LIGHTRED",
    xp_modifier = 12,
    genus_id = "MONS_ORANGE_DEMON",
    species_id = "MONS_ORANGE_DEMON",
    holiness = {
        "MH_DEMONIC",
    },
    willpower = 60,
    attacks = {
        {
            type_id = "AT_STING",
            flavour_id = "AF_REACH_STING",
            damage = 15,
        },
        {
            type_id = "AT_HIT",
            flavour_id = "AF_WEAKNESS",
            damage = 8,
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
    hd = 8,
    average_hp_10x = 520,
    ac = 3,
    ev = 7,
    spellbook_id = "MST_NO_SPELLS",
    shout_id = "S_SCREECH",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
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
    item_use_id = "MONUSE_OPEN_DOORS",
    size_id = "SIZE_MEDIUM",
    shape_id = "MON_SHAPE_HUMANOID_TAILED",
    tile = {
        id = "TILEP_MONS_ORANGE_DEMON",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
