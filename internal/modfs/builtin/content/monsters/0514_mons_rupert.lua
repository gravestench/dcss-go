-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:7635

local categories = require("constants.catalog")
local item_ids = require("ids.items")

local definition = {
    id = "MONS_RUPERT",
    status = "defined",
    name = "Rupert",
    glyph = 64,
    colour_id = "LIGHTRED",
    flags = {
        "M_UNIQUE",
        "M_WARM_BLOOD",
        "M_SPEAKS",
        "M_MALE",
    },
    xp_modifier = 18,
    genus_id = "MONS_HUMAN",
    species_id = "MONS_HUMAN",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 100,
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 21,
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
    hd = 16,
    average_hp_10x = 1200,
    ev = 10,
    spellbook_id = "MST_RUPERT",
    leaves_corpse = true,
    shout_id = "S_SHOUT",
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
    item_use_id = "MONUSE_WEAPONS_ARMOUR",
    size_id = "SIZE_MEDIUM",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_RUPERT",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
    weapon_gear = {
        -- Source: crawl-ref/source/mon-gear.cc:594
        -- Spec: crawl-ref/source/mon-gear.cc:597
        -- Weapon list: crawl-ref/source/mon-gear.cc:597
        -- Brand list: crawl-ref/source/mon-gear.cc:602
        primary = {
            weapons = {
                {
                    id = item_ids.WPN_GREAT_MACE,
                    weight = 10,
                },
                {
                    id = item_ids.WPN_GREAT_SWORD,
                    weight = 6,
                },
                {
                    id = item_ids.WPN_TRIPLE_SWORD,
                    weight = 2,
                },
                {
                    id = item_ids.WPN_BATTLEAXE,
                    weight = 8,
                },
                {
                    id = item_ids.WPN_EXECUTIONERS_AXE,
                    weight = 2,
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
