-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:5593

local categories = require("constants.catalog")
local item_ids = require("ids.items")

local definition = {
    id = "MONS_DEMONSPAWN_CORRUPTER",
    status = "defined",
    name = "demonspawn corrupter",
    glyph = 54,
    colour_id = "LIGHTGREEN",
    flags = {
        "M_WARM_BLOOD",
        "M_SPEAKS",
    },
    resistances = {
        {
            id = "MR_RES_NEG",
            level = 3,
        },
    },
    xp_modifier = 10,
    genus_id = "MONS_DEMONSPAWN",
    species_id = "MONS_DEMONSPAWN",
    holiness = {
        "MH_NATURAL",
        "MH_DEMONIC",
    },
    willpower = 60,
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 25,
        },
        {
            type_id = "AT_KICK",
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
    },
    hd = 15,
    average_hp_10x = 925,
    ac = 3,
    ev = 15,
    spellbook_id = "MST_DEMONSPAWN_CORRUPTER",
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
        id = "TILEP_MONS_DEMONSPAWN_CORRUPTER",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
    weapon_gear = {
        -- Source: crawl-ref/source/mon-gear.cc:877
        -- Spec: crawl-ref/source/mon-gear.cc:877
        -- Weapon list: crawl-ref/source/mon-gear.cc:416
        primary = {
            weapons = {
                {
                    id = item_ids.WPN_GREAT_SWORD,
                    weight = 3,
                },
                {
                    id = item_ids.WPN_DEMON_BLADE,
                    weight = 2,
                },
                {
                    id = item_ids.WPN_DIRE_FLAIL,
                    weight = 3,
                },
                {
                    id = item_ids.WPN_DEMON_WHIP,
                    weight = 2,
                },
                {
                    id = item_ids.WPN_GLAIVE,
                    weight = 3,
                },
                {
                    id = item_ids.WPN_DEMON_TRIDENT,
                    weight = 2,
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
