-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:1705

local categories = require("constants.catalog")
local curves = require("constants.population_curves")
local item_ids = require("ids.items")
local sentinels = require("constants.monster_gear_sentinels")

local definition = {
    id = "MONS_ORC_KNIGHT",
    status = "defined",
    name = "orc knight",
    glyph = 111,
    colour_id = "CYAN",
    flags = {
        "M_FIGHTER",
        "M_WARM_BLOOD",
        "M_SPEAKS",
    },
    xp_modifier = 9,
    genus_id = "MONS_ORC",
    species_id = "MONS_ORC",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 40,
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 25,
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
    average_hp_10x = 675,
    ac = 2,
    ev = 13,
    spellbook_id = "MST_ORC_KNIGHT",
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
        id = "TILEP_MONS_ORC_KNIGHT",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
    population = {
        -- Source line: 154
        {
            source_order = 85,
            min_depth = 15,
            max_depth = 24,
            rarity = 345,
            curve = curves.FALL,
        },
    },
    weapon_gear = {
        -- Source: crawl-ref/source/mon-gear.cc:608
        -- Spec: crawl-ref/source/mon-gear.cc:357
        -- Weapon list: crawl-ref/source/mon-gear.cc:346
        primary = {
            weapons = {
                {
                    id = item_ids.WPN_GREAT_SWORD,
                    weight = 4,
                },
                {
                    id = item_ids.WPN_LONG_SWORD,
                    weight = 4,
                },
                {
                    id = item_ids.WPN_BATTLEAXE,
                    weight = 4,
                },
                {
                    id = item_ids.WPN_WAR_AXE,
                    weight = 4,
                },
                {
                    id = item_ids.WPN_GREAT_MACE,
                    weight = 3,
                },
                {
                    id = item_ids.WPN_DIRE_FLAIL,
                    weight = 2,
                },
                {
                    id = item_ids.WPN_BARDICHE,
                    weight = 1,
                },
                {
                    id = item_ids.WPN_GLAIVE,
                    weight = 1,
                },
                {
                    id = item_ids.WPN_BROAD_AXE,
                    weight = 1,
                },
                {
                    id = item_ids.WPN_HALBERD,
                    weight = 1,
                },
            },
            plus = {
                odds = 4,
                min = 1,
                max = 3,
                rolls = 0,
            },
            brands = mod.null,
            good_chance = 0,
        },
        -- Source: crawl-ref/source/mon-gear.cc:957
        -- Spec: crawl-ref/source/mon-gear.cc:957
        -- Weapon list: crawl-ref/source/mon-gear.cc:936
        secondary = {
            weapons = {
                {
                    id = item_ids.WPN_ARBALEST,
                    weight = 1,
                },
                {
                    id = sentinels.NO_WEAPON,
                    weight = 8,
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
