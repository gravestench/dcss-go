-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:6979

local categories = require("constants.catalog")
local item_ids = require("ids.items")

local definition = {
    id = "MONS_THE_ENCHANTRESS",
    status = "defined",
    name = "the Enchantress",
    glyph = 105,
    colour_id = "LIGHTMAGENTA",
    flags = {
        "M_WARM_BLOOD",
        "M_SPEAKS",
        "M_SEE_INVIS",
        "M_UNIQUE",
        "M_FEMALE",
    },
    xp_modifier = 35,
    genus_id = "MONS_SPRIGGAN",
    species_id = "MONS_SPRIGGAN",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 160,
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 26,
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
    hd = 15,
    average_hp_10x = 975,
    ac = 1,
    ev = 30,
    spellbook_id = "MST_THE_ENCHANTRESS",
    leaves_corpse = true,
    shout_id = "S_SHOUT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    energy = {
        move = 6,
        swim = 6,
        attack = 10,
        missile = 10,
        spell = 10,
        special = 10,
        item = 10,
        pickup_percent = 100,
    },
    item_use_id = "MONUSE_WEAPONS_ARMOUR",
    size_id = "SIZE_LITTLE",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_THE_ENCHANTRESS",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
    weapon_gear = {
        -- Source: crawl-ref/source/mon-gear.cc:843
        -- Spec: crawl-ref/source/mon-gear.cc:843
        -- Weapon list: crawl-ref/source/mon-gear.cc:410
        -- Brand list: crawl-ref/source/mon-gear.cc:843
        primary = {
            weapons = {
                {
                    id = item_ids.WPN_LAJATANG,
                    weight = 1,
                },
                {
                    id = item_ids.WPN_QUICK_BLADE,
                    weight = 1,
                },
                {
                    id = item_ids.WPN_RAPIER,
                    weight = 1,
                },
                {
                    id = item_ids.WPN_DEMON_WHIP,
                    weight = 1,
                },
                {
                    id = item_ids.WPN_FLAIL,
                    weight = 1,
                },
            },
            plus = {
                odds = 0,
                min = 0,
                max = 0,
                rolls = 0,
            },
            brands = {
            },
            good_chance = 1,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
