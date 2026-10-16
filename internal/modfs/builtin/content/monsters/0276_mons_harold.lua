-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:7596

local categories = require("constants.catalog")
local item_ids = require("ids.items")

local definition = {
    id = "MONS_HAROLD",
    status = "defined",
    name = "Harold",
    glyph = 64,
    colour_id = "LIGHTGREEN",
    flags = {
        "M_UNIQUE",
        "M_FIGHTER",
        "M_WARM_BLOOD",
        "M_MALE",
        "M_SPEAKS",
    },
    xp_modifier = 20,
    genus_id = "MONS_HUMAN",
    species_id = "MONS_HUMAN",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 60,
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 20,
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
    hd = 9,
    average_hp_10x = 765,
    ev = 8,
    spellbook_id = "MST_HAROLD",
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
        id = "TILEP_MONS_HAROLD",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
    weapon_gear = {
        -- Source: crawl-ref/source/mon-gear.cc:577
        -- Spec: crawl-ref/source/mon-gear.cc:577
        -- Weapon list: crawl-ref/source/mon-gear.cc:331
        primary = {
            weapons = {
                {
                    id = item_ids.WPN_LONG_SWORD,
                    weight = 10,
                },
                {
                    id = item_ids.WPN_SHORT_SWORD,
                    weight = 10,
                },
                {
                    id = item_ids.WPN_SCIMITAR,
                    weight = 10,
                },
                {
                    id = item_ids.WPN_BATTLEAXE,
                    weight = 10,
                },
                {
                    id = item_ids.WPN_HAND_AXE,
                    weight = 10,
                },
                {
                    id = item_ids.WPN_HALBERD,
                    weight = 10,
                },
                {
                    id = item_ids.WPN_GLAIVE,
                    weight = 10,
                },
                {
                    id = item_ids.WPN_MACE,
                    weight = 10,
                },
                {
                    id = item_ids.WPN_DIRE_FLAIL,
                    weight = 10,
                },
                {
                    id = item_ids.WPN_TRIDENT,
                    weight = 10,
                },
                {
                    id = item_ids.WPN_WAR_AXE,
                    weight = 9,
                },
                {
                    id = item_ids.WPN_FLAIL,
                    weight = 9,
                },
                {
                    id = item_ids.WPN_BROAD_AXE,
                    weight = 1,
                },
                {
                    id = item_ids.WPN_MORNINGSTAR,
                    weight = 1,
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
