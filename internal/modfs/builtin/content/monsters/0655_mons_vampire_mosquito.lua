-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:2567

local categories = require("constants.catalog")

local definition = {
    id = "MONS_VAMPIRE_MOSQUITO",
    status = "defined",
    name = "vampire mosquito",
    glyph = 121,
    colour_id = "LIGHTGREY",
    flags = {
        "M_NO_SKELETON",
        "M_FLIES",
    },
    xp_modifier = 10,
    genus_id = "MONS_VAMPIRE_MOSQUITO",
    species_id = "MONS_VAMPIRE_MOSQUITO",
    holiness = {
        "MH_UNDEAD",
    },
    willpower = 20,
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_VAMPIRIC",
            damage = 13,
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
    hd = 5,
    average_hp_10x = 275,
    ac = 2,
    ev = 15,
    spellbook_id = "MST_NO_SPELLS",
    leaves_corpse = true,
    shout_id = "S_BUZZ",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 19,
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
    size_id = "SIZE_LITTLE",
    shape_id = "MON_SHAPE_INSECT_WINGED",
    tile = {
        id = "TILEP_MONS_VAMPIRE_MOSQUITO",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_VAMPIRE_MOSQUITO",
}

register.definition(categories.MONSTERS, definition)

return definition
