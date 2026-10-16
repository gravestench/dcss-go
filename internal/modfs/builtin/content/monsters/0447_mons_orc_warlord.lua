-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:1718

local categories = require("constants.catalog")
local curves = require("constants.population_curves")
local item_ids = require("ids.items")
local sentinels = require("constants.monster_gear_sentinels")

local definition = {
    id = "MONS_ORC_WARLORD",
    status = "defined",
    name = "orc warlord",
    glyph = 111,
    colour_id = "LIGHTCYAN",
    flags = {
        "M_FIGHTER",
        "M_WARM_BLOOD",
        "M_SPEAKS",
    },
    xp_modifier = 11,
    genus_id = "MONS_ORC",
    species_id = "MONS_ORC",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 60,
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 32,
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
    average_hp_10x = 1125,
    ac = 3,
    ev = 10,
    spellbook_id = "MST_BATTLECRY",
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
        id = "TILEP_MONS_ORC_WARLORD",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
    population = {
        -- Source line: 182
        {
            source_order = 113,
            min_depth = 23,
            max_depth = 27,
            rarity = 28,
            curve = curves.SEMI,
        },
    },
    weapon_gear = {
        -- Source: crawl-ref/source/mon-gear.cc:605
        -- Spec: crawl-ref/source/mon-gear.cc:359
        -- Weapon list: crawl-ref/source/mon-gear.cc:346
        -- Brand list: crawl-ref/source/mon-gear.cc:359
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
            brands = {
            },
            good_chance = 3,
        },
        -- Source: crawl-ref/source/mon-gear.cc:955
        -- Spec: crawl-ref/source/mon-gear.cc:955
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
