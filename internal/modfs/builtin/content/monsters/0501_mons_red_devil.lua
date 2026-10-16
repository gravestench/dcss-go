-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:5742

local categories = require("constants.catalog")
local item_ids = require("ids.items")

local definition = {
    id = "MONS_RED_DEVIL",
    status = "defined",
    name = "red devil",
    glyph = 52,
    colour_id = "RED",
    flags = {
        "M_FIGHTER",
        "M_FLIES",
    },
    resistances = {
        {
            id = "MR_RES_POISON",
            level = 1,
        },
        {
            id = "MR_RES_FIRE",
            level = 3,
        },
        {
            id = "MR_RES_COLD",
            level = -1,
        },
    },
    xp_modifier = 13,
    genus_id = "MONS_RED_DEVIL",
    species_id = "MONS_RED_DEVIL",
    holiness = {
        "MH_DEMONIC",
    },
    willpower = 60,
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_BARBS",
            damage = 19,
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
    hd = 7,
    average_hp_10x = 315,
    ac = 7,
    ev = 13,
    spellbook_id = "MST_NO_SPELLS",
    shout_id = "S_SILENT",
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
    shape_id = "MON_SHAPE_HUMANOID_WINGED",
    tile = {
        id = "TILEP_MONS_RED_DEVIL",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
    weapon_gear = {
        -- Source: crawl-ref/source/mon-gear.cc:634
        -- Spec: crawl-ref/source/mon-gear.cc:635
        -- Weapon list: crawl-ref/source/mon-gear.cc:635
        primary = {
            weapons = {
                {
                    id = item_ids.WPN_TRIDENT,
                    weight = 4,
                },
                {
                    id = item_ids.WPN_DEMON_TRIDENT,
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
