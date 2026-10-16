-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:4259

local categories = require("constants.catalog")
local curves = require("constants.population_curves")
local item_ids = require("ids.items")

local definition = {
    id = "MONS_TENGU_REAVER",
    status = "defined",
    name = "tengu reaver",
    glyph = 81,
    colour_id = "LIGHTMAGENTA",
    flags = {
        "M_FIGHTER",
        "M_SEE_INVIS",
        "M_WARM_BLOOD",
        "M_SPEAKS",
        "M_FLIES",
    },
    xp_modifier = 13,
    genus_id = "MONS_TENGU",
    species_id = "MONS_TENGU",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 60,
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 27,
        },
        {
            type_id = "AT_PECK",
            flavour_id = "AF_PLAIN",
            damage = 11,
        },
        {
            type_id = "AT_CLAW",
            flavour_id = "AF_PLAIN",
            damage = 11,
        },
        {
            type_id = "AT_NONE",
            flavour_id = "AF_PLAIN",
            damage = 0,
        },
    },
    hd = 17,
    average_hp_10x = 850,
    ac = 2,
    ev = 17,
    spellbook_id = "MST_TENGU_REAVER",
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
        id = "TILEP_MONS_TENGU_REAVER",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
    population = {
        -- Source line: 189
        {
            source_order = 120,
            min_depth = 24,
            max_depth = 27,
            rarity = 136,
            curve = curves.RISE,
        },
    },
    weapon_gear = {
        -- Source: crawl-ref/source/mon-gear.cc:603
        -- Spec: crawl-ref/source/mon-gear.cc:359
        -- Weapon list: crawl-ref/source/mon-gear.cc:346
        -- Brand list: crawl-ref/source/mon-gear.cc:359
        primary = {
            weapons = {
                {
                    id = item_ids.WPN_GREAT_SWORD,
                    weight = 4,
                },
                {
                    id = item_ids.WPN_LONG_SWORD,
                    weight = 4,
                },
                {
                    id = item_ids.WPN_BATTLEAXE,
                    weight = 4,
                },
                {
                    id = item_ids.WPN_WAR_AXE,
                    weight = 4,
                },
                {
                    id = item_ids.WPN_GREAT_MACE,
                    weight = 3,
                },
                {
                    id = item_ids.WPN_DIRE_FLAIL,
                    weight = 2,
                },
                {
                    id = item_ids.WPN_BARDICHE,
                    weight = 1,
                },
                {
                    id = item_ids.WPN_GLAIVE,
                    weight = 1,
                },
                {
                    id = item_ids.WPN_BROAD_AXE,
                    weight = 1,
                },
                {
                    id = item_ids.WPN_HALBERD,
                    weight = 1,
                },
            },
            plus = {
                odds = 4,
                min = 1,
                max = 3,
                rolls = 0,
            },
            brands = {
            },
            good_chance = 3,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
