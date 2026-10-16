-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:1836

local categories = require("constants.catalog")
local item_ids = require("ids.items")
local sentinels = require("constants.monster_gear_sentinels")

local definition = {
    id = "MONS_VAULT_SENTINEL",
    status = "defined",
    name = "vault sentinel",
    glyph = 112,
    colour_id = "LIGHTBLUE",
    flags = {
        "M_FIGHTER",
        "M_WARM_BLOOD",
        "M_SEE_INVIS",
        "M_SPEAKS",
    },
    xp_modifier = 10,
    genus_id = "MONS_HUMAN",
    species_id = "MONS_HUMAN",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 40,
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 15,
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
    hd = 8,
    average_hp_10x = 520,
    ac = 1,
    ev = 13,
    spellbook_id = "MST_VAULT_SENTINEL",
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
        id = "TILEP_MONS_VAULT_SENTINEL",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
    weapon_gear = {
        -- Source: crawl-ref/source/mon-gear.cc:623
        -- Spec: crawl-ref/source/mon-gear.cc:624
        -- Weapon list: crawl-ref/source/mon-gear.cc:624
        primary = {
            weapons = {
                {
                    id = item_ids.WPN_LONG_SWORD,
                    weight = 5,
                },
                {
                    id = item_ids.WPN_FALCHION,
                    weight = 4,
                },
                {
                    id = item_ids.WPN_WAR_AXE,
                    weight = 3,
                },
                {
                    id = item_ids.WPN_MORNINGSTAR,
                    weight = 3,
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
        -- Source: crawl-ref/source/mon-gear.cc:964
        -- Spec: crawl-ref/source/mon-gear.cc:965
        -- Weapon list: crawl-ref/source/mon-gear.cc:965
        secondary = {
            weapons = {
                {
                    id = item_ids.WPN_ARBALEST,
                    weight = 19,
                },
                {
                    id = item_ids.WPN_HAND_CROSSBOW,
                    weight = 1,
                },
                {
                    id = sentinels.NO_WEAPON,
                    weight = 40,
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
