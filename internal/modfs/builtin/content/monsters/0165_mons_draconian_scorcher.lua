-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:732

local categories = require("constants.catalog")
local item_ids = require("ids.items")

local definition = {
    id = "MONS_DRACONIAN_SCORCHER",
    status = "defined",
    name = "draconian scorcher",
    glyph = 113,
    colour_id = "LIGHTRED",
    flags = {
        "M_COLD_BLOOD",
        "M_SPEAKS",
    },
    xp_modifier = 10,
    genus_id = "MONS_DRACONIAN",
    species_id = "MONS_DRACONIAN",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 40,
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
    hd = 16,
    average_hp_10x = 800,
    ac = -1,
    ev = 2,
    spellbook_id = "MST_DRACONIAN_SCORCHER",
    leaves_corpse = true,
    shout_id = "S_ROAR",
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
    shape_id = "MON_SHAPE_HUMANOID_TAILED",
    tile = {
        id = "TILEP_DRACO_SCORCHER",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
    weapon_gear = {
        -- Source: crawl-ref/source/mon-gear.cc:563
        -- Spec: crawl-ref/source/mon-gear.cc:563
        -- Weapon list: crawl-ref/source/mon-gear.cc:325
        primary = {
            weapons = {
                {
                    id = item_ids.WPN_LONG_SWORD,
                    weight = 2,
                },
                {
                    id = item_ids.WPN_SHORT_SWORD,
                    weight = 1,
                },
                {
                    id = item_ids.WPN_RAPIER,
                    weight = 1,
                },
                {
                    id = item_ids.WPN_DAGGER,
                    weight = 1,
                },
                {
                    id = item_ids.WPN_WHIP,
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
