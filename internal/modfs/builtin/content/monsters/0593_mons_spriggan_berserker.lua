-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:1317

local categories = require("constants.catalog")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")
local sentinels = require("constants.monster_gear_sentinels")

local definition = {
    id = "MONS_SPRIGGAN_BERSERKER",
    status = "defined",
    name = "spriggan berserker",
    glyph = 105,
    colour_id = "LIGHTRED",
    flags = {
        "M_WARM_BLOOD",
        "M_SPEAKS",
        "M_SEE_INVIS",
        "M_FIGHTER",
    },
    xp_modifier = 10,
    genus_id = "MONS_SPRIGGAN",
    species_id = "MONS_SPRIGGAN",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 120,
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 27,
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
    average_hp_10x = 540,
    ac = 2,
    ev = 18,
    spellbook_id = "MST_SPRIGGAN_BERSERKER",
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
        id = "TILEP_MONS_SPRIGGAN_BERSERKER",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
    weapon_gear = {
        -- Source: crawl-ref/source/mon-gear.cc:832
        -- Spec: crawl-ref/source/mon-gear.cc:832
        -- Weapon list: crawl-ref/source/mon-gear.cc:833
        -- Brand list: crawl-ref/source/mon-gear.cc:839
        primary = {
            weapons = {
                {
                    id = item_ids.WPN_QUARTERSTAFF,
                    weight = 10,
                },
                {
                    id = item_ids.WPN_HAND_AXE,
                    weight = 9,
                },
                {
                    id = item_ids.WPN_WAR_AXE,
                    weight = 12,
                },
                {
                    id = item_ids.WPN_BROAD_AXE,
                    weight = 5,
                },
                {
                    id = item_ids.WPN_FLAIL,
                    weight = 5,
                },
                {
                    id = item_ids.WPN_RAPIER,
                    weight = 10,
                },
            },
            plus = {
                odds = 0,
                min = 0,
                max = 0,
                rolls = 0,
            },
            brands = {
                {
                    id = brands.ANTIMAGIC,
                    weight = 1,
                },
                {
                    id = sentinels.NO_FORCED_BRAND,
                    weight = 3,
                },
            },
            good_chance = 0,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
