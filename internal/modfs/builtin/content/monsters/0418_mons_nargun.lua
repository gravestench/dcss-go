-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:6379

local categories = require("constants.catalog")

local definition = {
    id = "MONS_NARGUN",
    status = "defined",
    name = "nargun",
    glyph = 57,
    colour_id = "BLUE",
    flags = {
        "M_SEE_INVIS",
        "M_FIGHTER",
    },
    resistances = {
        {
            id = "MR_RES_ELEC",
            level = 1,
        },
        {
            id = "MR_RES_COLD",
            level = 3,
        },
        {
            id = "MR_RES_PETRIFY",
            level = 1,
        },
    },
    xp_modifier = 10,
    genus_id = "MONS_GOLEM",
    species_id = "MONS_NARGUN",
    holiness = {
        "MH_NONLIVING",
    },
    willpower = 100,
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_VULN",
            damage = 40,
        },
        {
            type_id = "AT_BITE",
            flavour_id = "AF_COLD",
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
    },
    hd = 22,
    average_hp_10x = 540,
    ac = 25,
    ev = 4,
    spellbook_id = "MST_NARGUN",
    shout_id = "S_SILENT",
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
    item_use_id = "MONUSE_NOTHING",
    size_id = "SIZE_MEDIUM",
    shape_id = "MON_SHAPE_BLOB",
    tile = {
        id = "TILEP_MONS_NARGUN",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
