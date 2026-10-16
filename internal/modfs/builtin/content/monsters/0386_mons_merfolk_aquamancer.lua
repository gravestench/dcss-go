-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:1534

local categories = require("constants.catalog")
local item_ids = require("ids.items")

local definition = {
    id = "MONS_MERFOLK_AQUAMANCER",
    status = "defined",
    name = "merfolk aquamancer",
    glyph = 109,
    colour_id = "GREEN",
    flags = {
        "M_WARM_BLOOD",
        "M_SPEAKS",
        "M_SEE_INVIS",
    },
    xp_modifier = 8,
    genus_id = "MONS_MERFOLK",
    species_id = "MONS_MERFOLK",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 80,
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 15,
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
    hd = 14,
    average_hp_10x = 630,
    ev = 12,
    spellbook_id = "MST_MERFOLK_AQUAMANCER",
    leaves_corpse = true,
    shout_id = "S_SHOUT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_AMPHIBIOUS",
    speed = 10,
    energy = {
        move = 10,
        swim = 6,
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
        id = "TILEP_MONS_MERFOLK_AQUAMANCER",
        variation_id = "TVARY_WATER",
    },
    corpse_tile_id = "TILE_ERROR",
    weapon_gear = {
        -- Source: crawl-ref/source/mon-gear.cc:663
        -- Spec: crawl-ref/source/mon-gear.cc:663
        -- Weapon list: crawl-ref/source/mon-gear.cc:663
        -- Brand list: crawl-ref/source/mon-gear.cc:663
        primary = {
            weapons = {
                {
                    id = item_ids.WPN_RAPIER,
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
            },
            good_chance = 2,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
