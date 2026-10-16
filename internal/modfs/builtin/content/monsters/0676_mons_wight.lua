-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:2662

local categories = require("constants.catalog")
local curves = require("constants.population_curves")
local item_ids = require("ids.items")

local definition = {
    id = "MONS_WIGHT",
    status = "defined",
    name = "wight",
    glyph = 122,
    colour_id = "GREEN",
    resistances = {
        {
            id = "MR_RES_COLD",
            level = 2,
        },
    },
    xp_modifier = 20,
    genus_id = "MONS_WIGHT",
    species_id = "MONS_WIGHT",
    holiness = {
        "MH_UNDEAD",
    },
    willpower = 20,
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_DRAIN",
            damage = 8,
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
    average_hp_10x = 165,
    ac = 4,
    ev = 10,
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
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_WIGHT",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
    population = {
        -- Source line: 110
        {
            source_order = 41,
            min_depth = 6,
            max_depth = 10,
            rarity = 500,
            curve = curves.PEAK,
        },
    },
    weapon_gear = {
        -- Source: crawl-ref/source/mon-gear.cc:442
        -- Spec: crawl-ref/source/mon-gear.cc:443
        -- Weapon list: crawl-ref/source/mon-gear.cc:443
        primary = {
            weapons = {
                {
                    id = item_ids.WPN_MORNINGSTAR,
                    weight = 4,
                },
                {
                    id = item_ids.WPN_DIRE_FLAIL,
                    weight = 4,
                },
                {
                    id = item_ids.WPN_WAR_AXE,
                    weight = 4,
                },
                {
                    id = item_ids.WPN_TRIDENT,
                    weight = 4,
                },
                {
                    id = item_ids.WPN_MACE,
                    weight = 7,
                },
                {
                    id = item_ids.WPN_FLAIL,
                    weight = 7,
                },
                {
                    id = item_ids.WPN_FALCHION,
                    weight = 7,
                },
                {
                    id = item_ids.WPN_DAGGER,
                    weight = 7,
                },
                {
                    id = item_ids.WPN_SHORT_SWORD,
                    weight = 7,
                },
                {
                    id = item_ids.WPN_LONG_SWORD,
                    weight = 7,
                },
                {
                    id = item_ids.WPN_SCIMITAR,
                    weight = 7,
                },
                {
                    id = item_ids.WPN_GREAT_SWORD,
                    weight = 7,
                },
                {
                    id = item_ids.WPN_HAND_AXE,
                    weight = 7,
                },
                {
                    id = item_ids.WPN_BATTLEAXE,
                    weight = 7,
                },
                {
                    id = item_ids.WPN_SPEAR,
                    weight = 7,
                },
                {
                    id = item_ids.WPN_HALBERD,
                    weight = 7,
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
