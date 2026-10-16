-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:2799

local categories = require("constants.catalog")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = "MONS_DAEVA",
    status = "defined",
    name = "daeva",
    glyph = 65,
    colour_id = "YELLOW",
    flags = {
        "M_FIGHTER",
        "M_SPEAKS",
        "M_FLIES",
    },
    resistances = {
        {
            id = "MR_RES_POISON",
            level = 1,
        },
    },
    xp_modifier = 12,
    genus_id = "MONS_ANGEL",
    species_id = "MONS_DAEVA",
    holiness = {
        "MH_HOLY",
    },
    willpower = 140,
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 25,
        },
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 10,
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
    hd = 14,
    average_hp_10x = 1190,
    ac = 10,
    ev = 13,
    spellbook_id = "MST_DAEVA",
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
    shape_id = "MON_SHAPE_HUMANOID_WINGED",
    tile = {
        id = "TILEP_MONS_DAEVA",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
    weapon_gear = {
        -- Source: crawl-ref/source/mon-gear.cc:711
        -- Spec: crawl-ref/source/mon-gear.cc:383
        -- Weapon list: crawl-ref/source/mon-gear.cc:383
        -- Brand list: crawl-ref/source/mon-gear.cc:387
        primary = {
            weapons = {
                {
                    id = item_ids.WPN_EUDEMON_BLADE,
                    weight = 1,
                },
                {
                    id = item_ids.WPN_SCIMITAR,
                    weight = 2,
                },
                {
                    id = item_ids.WPN_LONG_SWORD,
                    weight = 1,
                },
            },
            plus = {
                odds = 1,
                min = 2,
                max = 5,
                rolls = 0,
            },
            brands = {
                {
                    id = brands.HOLY_WRATH,
                    weight = 1,
                },
            },
            good_chance = 0,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
