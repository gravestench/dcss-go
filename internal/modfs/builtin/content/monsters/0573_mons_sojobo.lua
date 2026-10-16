-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:7218

local categories = require("constants.catalog")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")
local sentinels = require("constants.monster_gear_sentinels")

local definition = {
    id = "MONS_SOJOBO",
    status = "defined",
    name = "Sojobo",
    glyph = 81,
    colour_id = "LIGHTGREEN",
    flags = {
        "M_FIGHTER",
        "M_SEE_INVIS",
        "M_WARM_BLOOD",
        "M_SPEAKS",
        "M_UNIQUE",
        "M_FEMALE",
        "M_FLIES",
    },
    xp_modifier = 20,
    genus_id = "MONS_TENGU",
    species_id = "MONS_TENGU",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 140,
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 28,
        },
        {
            type_id = "AT_PECK",
            flavour_id = "AF_PLAIN",
            damage = 14,
        },
        {
            type_id = "AT_CLAW",
            flavour_id = "AF_PLAIN",
            damage = 14,
        },
        {
            type_id = "AT_NONE",
            flavour_id = "AF_PLAIN",
            damage = 0,
        },
    },
    hd = 20,
    average_hp_10x = 1500,
    ac = 2,
    ev = 24,
    spellbook_id = "MST_SOJOBO",
    leaves_corpse = true,
    shout_id = "S_SHOUT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    energy = {
        move = 9,
        swim = 9,
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
        id = "TILEP_MONS_SOJOBO",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
    weapon_gear = {
        -- Source: crawl-ref/source/mon-gear.cc:862
        -- Spec: crawl-ref/source/mon-gear.cc:862
        -- Weapon list: crawl-ref/source/mon-gear.cc:863
        -- Brand list: crawl-ref/source/mon-gear.cc:865
        primary = {
            weapons = {
                {
                    id = item_ids.WPN_TRIPLE_SWORD,
                    weight = 1,
                },
                {
                    id = item_ids.WPN_GREAT_SWORD,
                    weight = 5,
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
                    id = brands.ELECTROCUTION,
                    weight = 2,
                },
                {
                    id = sentinels.NO_FORCED_BRAND,
                    weight = 1,
                },
            },
            good_chance = 1,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
