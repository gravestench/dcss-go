-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:1679

local categories = require("constants.catalog")
local curves = require("constants.population_curves")
local item_ids = require("ids.items")

local definition = {
    id = "MONS_ORC_PRIEST",
    status = "defined",
    name = "orc priest",
    glyph = 111,
    colour_id = "GREEN",
    flags = {
        "M_WARM_BLOOD",
        "M_SPEAKS",
    },
    xp_modifier = 10,
    genus_id = "MONS_ORC",
    species_id = "MONS_ORC",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 20,
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 3,
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
    hd = 3,
    average_hp_10x = 150,
    ac = 1,
    ev = 10,
    spellbook_id = "MST_ORC_PRIEST",
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
        id = "TILEP_MONS_ORC_PRIEST",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
    population = {
        -- Source line: 98
        {
            source_order = 30,
            min_depth = 4,
            max_depth = 12,
            rarity = 150,
            curve = curves.PEAK,
        },
    },
    weapon_gear = {
        -- Source: crawl-ref/source/mon-gear.cc:507
        -- Spec: crawl-ref/source/mon-gear.cc:507
        -- Weapon list: crawl-ref/source/mon-gear.cc:302
        primary = {
            weapons = {
                {
                    id = item_ids.WPN_CLUB,
                    weight = 100,
                },
                {
                    id = item_ids.WPN_DAGGER,
                    weight = 80,
                },
                {
                    id = item_ids.WPN_FLAIL,
                    weight = 60,
                },
                {
                    id = item_ids.WPN_SHORT_SWORD,
                    weight = 60,
                },
                {
                    id = item_ids.WPN_HAND_AXE,
                    weight = 80,
                },
                {
                    id = item_ids.WPN_WHIP,
                    weight = 45,
                },
                {
                    id = item_ids.WPN_MACE,
                    weight = 40,
                },
                {
                    id = item_ids.WPN_TRIDENT,
                    weight = 20,
                },
                {
                    id = item_ids.WPN_FALCHION,
                    weight = 20,
                },
                {
                    id = item_ids.WPN_WAR_AXE,
                    weight = 14,
                },
                {
                    id = item_ids.WPN_MORNINGSTAR,
                    weight = 6,
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
