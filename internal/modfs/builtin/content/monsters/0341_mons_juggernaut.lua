-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:3007

local categories = require("constants.catalog")

local definition = {
    id = "MONS_JUGGERNAUT",
    status = "defined",
    name = "juggernaut",
    glyph = 67,
    colour_id = "LIGHTGREEN",
    flags = {
        "M_FIGHTER",
        "M_WARM_BLOOD",
        "M_SEE_INVIS",
        "M_SPEAKS",
    },
    xp_modifier = 12,
    genus_id = "MONS_GIANT",
    species_id = "MONS_JUGGERNAUT",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 120,
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 80,
        },
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 40,
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
    average_hp_10x = 1700,
    ac = 20,
    ev = 5,
    spellbook_id = "MST_NO_SPELLS",
    leaves_corpse = true,
    shout_id = "S_SHOUT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
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
    item_use_id = "MONUSE_OPEN_DOORS",
    size_id = "SIZE_GIANT",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_JUGGERNAUT",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_JUGGERNAUT",
}

register.definition(categories.MONSTERS, definition)

return definition
