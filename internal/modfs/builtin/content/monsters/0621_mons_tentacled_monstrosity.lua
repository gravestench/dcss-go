-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:4832

local categories = require("constants.catalog")

local definition = {
    id = "MONS_TENTACLED_MONSTROSITY",
    status = "defined",
    name = "tentacled monstrosity",
    glyph = 88,
    colour_id = "GREEN",
    flags = {
        "M_SEE_INVIS",
    },
    resistances = {
        {
            id = "MR_RES_POISON",
            level = 1,
        },
        {
            id = "MR_RES_FIRE",
            level = 1,
        },
        {
            id = "MR_RES_COLD",
            level = 1,
        },
        {
            id = "MR_RES_ELEC",
            level = 1,
        },
    },
    xp_modifier = 10,
    genus_id = "MONS_TENTACLED_MONSTROSITY",
    species_id = "MONS_TENTACLED_MONSTROSITY",
    holiness = {
        "MH_DEMONIC",
    },
    willpower = 160,
    attacks = {
        {
            type_id = "AT_TENTACLE_SLAP",
            flavour_id = "AF_PLAIN",
            damage = 22,
        },
        {
            type_id = "AT_TENTACLE_SLAP",
            flavour_id = "AF_PLAIN",
            damage = 17,
        },
        {
            type_id = "AT_TENTACLE_SLAP",
            flavour_id = "AF_PLAIN",
            damage = 13,
        },
        {
            type_id = "AT_CONSTRICT",
            flavour_id = "AF_CRUSH",
            damage = 9,
        },
    },
    hd = 23,
    average_hp_10x = 1265,
    ac = 5,
    ev = 5,
    spellbook_id = "MST_NO_SPELLS",
    shout_id = "S_SILENT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_AMPHIBIOUS",
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
    size_id = "SIZE_GIANT",
    shape_id = "MON_SHAPE_MISC",
    tile = {
        id = "TILEP_MONS_TENTACLED_MONSTROSITY",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
