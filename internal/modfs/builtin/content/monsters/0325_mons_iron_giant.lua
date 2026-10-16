-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:3020

local categories = require("constants.catalog")
local item_ids = require("ids.items")

local definition = {
    id = "MONS_IRON_GIANT",
    status = "defined",
    name = "iron giant",
    glyph = 67,
    colour_id = "CYAN",
    flags = {
        "M_WARM_BLOOD",
        "M_SPEAKS",
        "M_FIGHTER",
        "M_SEE_INVIS",
    },
    resistances = {
        {
            id = "MR_RES_POISON",
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
    },
    xp_modifier = 10,
    genus_id = "MONS_GIANT",
    species_id = "MONS_IRON_GIANT",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 120,
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 65,
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
    hd = 18,
    average_hp_10x = 1800,
    ac = 18,
    ev = 2,
    spellbook_id = "MST_IRON_GIANT",
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
    item_use_id = "MONUSE_STARTING_EQUIPMENT",
    size_id = "SIZE_GIANT",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_IRON_GIANT",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_IRON_GIANT",
    weapon_gear = {
        -- Source: crawl-ref/source/mon-gear.cc:639
        -- Spec: crawl-ref/source/mon-gear.cc:639
        -- Weapon list: crawl-ref/source/mon-gear.cc:370
        primary = {
            weapons = {
                {
                    id = item_ids.WPN_GIANT_CLUB,
                    weight = 60,
                },
                {
                    id = item_ids.WPN_GIANT_SPIKED_CLUB,
                    weight = 30,
                },
                {
                    id = item_ids.WPN_DIRE_FLAIL,
                    weight = 9,
                },
                {
                    id = item_ids.WPN_GREAT_MACE,
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
