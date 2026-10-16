-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:7661

local categories = require("constants.catalog")
local item_ids = require("ids.items")

local definition = {
    id = "MONS_FREDERICK",
    status = "defined",
    name = "Frederick",
    glyph = 64,
    colour_id = "GREEN",
    flags = {
        "M_UNIQUE",
        "M_WARM_BLOOD",
        "M_SEE_INVIS",
        "M_SPEAKS",
        "M_MALE",
    },
    xp_modifier = 15,
    genus_id = "MONS_DEMIGOD",
    species_id = "MONS_DEMIGOD",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 140,
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
    hd = 21,
    average_hp_10x = 1575,
    ev = 10,
    spellbook_id = "MST_FREDERICK",
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
        id = "TILEP_MONS_FREDERICK",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
    weapon_gear = {
        -- Source: crawl-ref/source/mon-gear.cc:777
        -- Spec: crawl-ref/source/mon-gear.cc:777
        -- Weapon list: crawl-ref/source/mon-gear.cc:397
        primary = {
            weapons = {
                {
                    id = item_ids.WPN_HALBERD,
                    weight = 5,
                },
                {
                    id = item_ids.WPN_GLAIVE,
                    weight = 5,
                },
                {
                    id = item_ids.WPN_WAR_AXE,
                    weight = 6,
                },
                {
                    id = item_ids.WPN_GREAT_MACE,
                    weight = 6,
                },
                {
                    id = item_ids.WPN_BATTLEAXE,
                    weight = 7,
                },
                {
                    id = item_ids.WPN_LONG_SWORD,
                    weight = 8,
                },
                {
                    id = item_ids.WPN_SCIMITAR,
                    weight = 8,
                },
                {
                    id = item_ids.WPN_GREAT_SWORD,
                    weight = 8,
                },
                {
                    id = item_ids.WPN_BROAD_AXE,
                    weight = 9,
                },
                {
                    id = item_ids.WPN_DOUBLE_SWORD,
                    weight = 10,
                },
                {
                    id = item_ids.WPN_EVENINGSTAR,
                    weight = 13,
                },
                {
                    id = item_ids.WPN_DEMON_TRIDENT,
                    weight = 14,
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
