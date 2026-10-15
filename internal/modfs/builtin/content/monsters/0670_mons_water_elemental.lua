-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:3282

local categories = require("constants.catalog")

local definition = {
    id = "MONS_WATER_ELEMENTAL",
    status = "defined",
    name = "water elemental",
    glyph = 69,
    colour_id = "ETC_WATER",
    flags = {
        "M_UNBLINDABLE",
    },
    resistances = {
        {
            id = "MR_RES_FIRE",
            level = -1,
        },
        {
            id = "MR_RES_ELEC",
            level = 1,
        },
    },
    xp_modifier = 12,
    genus_id = "MONS_ELEMENTAL",
    species_id = "MONS_WATER_ELEMENTAL",
    holiness = {
        "MH_NONLIVING",
    },
    willpower = 5000,
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_ENGULF",
            damage = 22,
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
    hd = 6,
    average_hp_10x = 420,
    ac = 4,
    ev = 7,
    spellbook_id = "MST_NO_SPELLS",
    shout_id = "S_SILENT",
    intelligence_id = "I_BRAINLESS",
    habitat_id = "HT_AMPHIBIOUS",
    speed = 10,
    energy = {
        move = 10,
        swim = 6,
        attack = 10,
        missile = 10,
        spell = 10,
        special = 10,
        item = 10,
        pickup_percent = 100,
    },
    item_use_id = "MONUSE_NOTHING",
    size_id = "SIZE_LARGE",
    shape_id = "MON_SHAPE_MISC",
    tile = {
        id = "TILEP_MONS_WATER_ELEMENTAL",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
