-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:3931

local categories = require("constants.catalog")
local item_ids = require("ids.items")

local definition = {
    id = "MONS_NAGA_MAGE",
    status = "defined",
    name = "naga mage",
    glyph = 78,
    colour_id = "MAGENTA",
    flags = {
        "M_SEE_INVIS",
        "M_WARM_BLOOD",
        "M_SPEAKS",
    },
    resistances = {
        {
            id = "MR_RES_POISON",
            level = 1,
        },
    },
    xp_modifier = 14,
    genus_id = "MONS_NAGA",
    species_id = "MONS_NAGA",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 60,
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 14,
        },
        {
            type_id = "AT_CONSTRICT",
            flavour_id = "AF_CRUSH",
            damage = 4,
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
    hd = 7,
    average_hp_10x = 385,
    ac = 6,
    ev = 10,
    spellbook_id = "MST_NAGA_MAGE",
    leaves_corpse = true,
    shout_id = "S_SHOUT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    energy = {
        move = 14,
        swim = 14,
        attack = 10,
        missile = 10,
        spell = 10,
        special = 10,
        item = 10,
        pickup_percent = 100,
    },
    item_use_id = "MONUSE_WEAPONS_ARMOUR",
    size_id = "SIZE_LARGE",
    shape_id = "MON_SHAPE_NAGA",
    tile = {
        id = "TILEP_MONS_NAGA_MAGE",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
    weapon_gear = {
        -- Source: crawl-ref/source/mon-gear.cc:475
        -- Spec: crawl-ref/source/mon-gear.cc:475
        -- Weapon list: crawl-ref/source/mon-gear.cc:296
        primary = {
            weapons = {
                {
                    id = item_ids.WPN_SPEAR,
                    weight = 8,
                },
                {
                    id = item_ids.WPN_HALBERD,
                    weight = 4,
                },
                {
                    id = item_ids.WPN_CLUB,
                    weight = 6,
                },
                {
                    id = item_ids.WPN_WHIP,
                    weight = 6,
                },
                {
                    id = item_ids.WPN_FLAIL,
                    weight = 6,
                },
            },
            plus = {
                odds = 0,
                min = 0,
                max = 0,
                rolls = 0,
            },
            brands = mod.null,
            good_chance = 0,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
