-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:4902

local categories = require("constants.catalog")

local definition = {
    id = "MONS_STARCURSED_MASS",
    status = "defined",
    name = "starcursed mass",
    glyph = 88,
    colour_id = "BLUE",
    flags = {
        "M_SEE_INVIS",
        "M_FAST_REGEN",
    },
    xp_modifier = 12,
    genus_id = "MONS_STARCURSED_MASS",
    species_id = "MONS_STARCURSED_MASS",
    holiness = {
        "MH_NONLIVING",
    },
    willpower = 100,
    attacks = {
        {
            type_id = "AT_TOUCH",
            flavour_id = "AF_PLAIN",
            damage = 16,
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
    hd = 12,
    average_hp_10x = 1500,
    ac = 10,
    spellbook_id = "MST_NO_SPELLS",
    shout_id = "S_SILENT",
    intelligence_id = "I_ANIMAL",
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
    item_use_id = "MONUSE_NOTHING",
    size_id = "SIZE_GIANT",
    shape_id = "MON_SHAPE_MISC",
    tile = {
        id = "TILEP_MONS_STARCURSED_MASS",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
