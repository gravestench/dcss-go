-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:2968

local categories = require("constants.catalog")
local curves = require("constants.population_curves")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = "MONS_FROST_GIANT",
    status = "defined",
    name = "frost giant",
    glyph = 67,
    colour_id = "LIGHTBLUE",
    flags = {
        "M_FIGHTER",
        "M_WARM_BLOOD",
        "M_SEE_INVIS",
        "M_SPEAKS",
    },
    resistances = {
        {
            id = "MR_RES_COLD",
            level = 2,
        },
    },
    xp_modifier = 11,
    genus_id = "MONS_GIANT",
    species_id = "MONS_FROST_GIANT",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 80,
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 35,
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
    hd = 16,
    average_hp_10x = 1040,
    ac = 9,
    ev = 3,
    spellbook_id = "MST_FROST_GIANT",
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
    size_id = "SIZE_GIANT",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_FROST_GIANT",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_FROST_GIANT",
    population = {
        -- Source line: 176
        {
            source_order = 107,
            min_depth = 20,
            max_depth = 30,
            rarity = 136,
            curve = curves.SEMI,
        },
    },
    weapon_gear = {
        -- Source: crawl-ref/source/mon-gear.cc:782
        -- Spec: crawl-ref/source/mon-gear.cc:782
        -- Weapon list: crawl-ref/source/mon-gear.cc:783
        -- Brand list: crawl-ref/source/mon-gear.cc:784
        primary = {
            weapons = {
                {
                    id = item_ids.WPN_BATTLEAXE,
                    weight = 1,
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
                    id = brands.FREEZING,
                    weight = 1,
                },
            },
            good_chance = 0,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
