-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:7408

local categories = require("constants.catalog")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = "MONS_IGNACIO",
    status = "defined",
    name = "Ignacio",
    glyph = 49,
    colour_id = "LIGHTMAGENTA",
    flags = {
        "M_UNIQUE",
        "M_FIGHTER",
        "M_SEE_INVIS",
        "M_SPEAKS",
        "M_MALE",
    },
    resistances = {
        {
            id = "MR_RES_ELEC",
            level = 1,
        },
        {
            id = "MR_RES_FIRE",
            level = 1,
        },
        {
            id = "MR_RES_COLD",
            level = 1,
        },
        {
            id = "MR_RES_POISON",
            level = 1,
        },
    },
    xp_modifier = 14,
    genus_id = "MONS_EXECUTIONER",
    species_id = "MONS_EXECUTIONER",
    holiness = {
        "MH_DEMONIC",
    },
    willpower = 160,
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 20,
        },
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 10,
        },
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 10,
        },
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 5,
        },
    },
    hd = 18,
    average_hp_10x = 2520,
    ac = 10,
    ev = 15,
    spellbook_id = "MST_IGNACIO",
    shout_id = "S_SHOUT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 20,
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
    item_use_id = "MONUSE_STARTING_EQUIPMENT",
    size_id = "SIZE_LARGE",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_IGNACIO",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
    weapon_gear = {
        -- Source: crawl-ref/source/mon-gear.cc:845
        -- Spec: crawl-ref/source/mon-gear.cc:845
        -- Weapon list: crawl-ref/source/mon-gear.cc:846
        -- Brand list: crawl-ref/source/mon-gear.cc:848
        primary = {
            weapons = {
                {
                    id = item_ids.WPN_EXECUTIONERS_AXE,
                    weight = 1,
                },
            },
            plus = {
                odds = 1,
                min = 2,
                max = 8,
                rolls = 0,
            },
            brands = {
                {
                    id = brands.PAIN,
                    weight = 1,
                },
            },
            good_chance = 0,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
