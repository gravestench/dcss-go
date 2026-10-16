-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:7687

local categories = require("constants.catalog")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")
local sentinels = require("constants.monster_gear_sentinels")

local definition = {
    id = "MONS_MARGERY",
    status = "defined",
    name = "Margery",
    glyph = 64,
    colour_id = "LIGHTRED",
    flags = {
        "M_UNIQUE",
        "M_WARM_BLOOD",
        "M_SEE_INVIS",
        "M_SPEAKS",
        "M_FEMALE",
    },
    xp_modifier = 15,
    genus_id = "MONS_HUMAN",
    species_id = "MONS_HUMAN",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 140,
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
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
        {
            type_id = "AT_NONE",
            flavour_id = "AF_PLAIN",
            damage = 0,
        },
    },
    hd = 22,
    average_hp_10x = 1650,
    ev = 10,
    spellbook_id = "MST_MARGERY",
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
        id = "TILEP_MONS_MARGERY",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
    weapon_gear = {
        -- Source: crawl-ref/source/mon-gear.cc:760
        -- Spec: crawl-ref/source/mon-gear.cc:761
        -- Weapon list: crawl-ref/source/mon-gear.cc:761
        -- Brand list: crawl-ref/source/mon-gear.cc:389
        primary = {
            weapons = {
                {
                    id = item_ids.WPN_DEMON_WHIP,
                    weight = 2,
                },
                {
                    id = item_ids.WPN_DEMON_BLADE,
                    weight = 2,
                },
                {
                    id = item_ids.WPN_DEMON_TRIDENT,
                    weight = 2,
                },
                {
                    id = item_ids.WPN_HALBERD,
                    weight = 1,
                },
                {
                    id = item_ids.WPN_GLAIVE,
                    weight = 1,
                },
                {
                    id = item_ids.WPN_WAR_AXE,
                    weight = 1,
                },
                {
                    id = item_ids.WPN_GREAT_MACE,
                    weight = 1,
                },
                {
                    id = item_ids.WPN_BATTLEAXE,
                    weight = 1,
                },
                {
                    id = item_ids.WPN_LONG_SWORD,
                    weight = 1,
                },
                {
                    id = item_ids.WPN_SCIMITAR,
                    weight = 1,
                },
                {
                    id = item_ids.WPN_GREAT_SWORD,
                    weight = 1,
                },
                {
                    id = item_ids.WPN_BROAD_AXE,
                    weight = 1,
                },
            },
            plus = {
                odds = 1,
                min = 0,
                max = 5,
                rolls = 0,
            },
            brands = {
                {
                    id = brands.FLAMING,
                    weight = 13,
                },
                {
                    id = brands.DRAINING,
                    weight = 4,
                },
                {
                    id = brands.VORPAL,
                    weight = 4,
                },
                {
                    id = brands.DISTORTION,
                    weight = 2,
                },
                {
                    id = brands.PAIN,
                    weight = 2,
                },
                {
                    id = sentinels.NO_FORCED_BRAND,
                    weight = 20,
                },
            },
            good_chance = 0,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
