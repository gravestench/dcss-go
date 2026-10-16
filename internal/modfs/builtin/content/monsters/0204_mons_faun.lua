-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:501

local categories = require("constants.catalog")
local item_ids = require("ids.items")

local definition = {
    id = "MONS_FAUN",
    status = "defined",
    name = "faun",
    glyph = 99,
    colour_id = "GREEN",
    flags = {
        "M_WARM_BLOOD",
        "M_SPEAKS",
    },
    xp_modifier = 8,
    genus_id = "MONS_FAUN",
    species_id = "MONS_FAUN",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 40,
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 23,
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
    hd = 10,
    average_hp_10x = 500,
    ac = 2,
    ev = 10,
    spellbook_id = "MST_FAUN",
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
    size_id = "SIZE_MEDIUM",
    shape_id = "MON_SHAPE_HUMANOID_TAILED",
    tile = {
        id = "TILEP_MONS_FAUN",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_FAUN",
    weapon_gear = {
        -- Source: crawl-ref/source/mon-gear.cc:676
        -- Spec: crawl-ref/source/mon-gear.cc:676
        -- Weapon list: crawl-ref/source/mon-gear.cc:375
        primary = {
            weapons = {
                {
                    id = item_ids.WPN_SPEAR,
                    weight = 2,
                },
                {
                    id = item_ids.WPN_CLUB,
                    weight = 1,
                },
                {
                    id = item_ids.WPN_QUARTERSTAFF,
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
        -- Source: crawl-ref/source/mon-gear.cc:969
        -- Spec: crawl-ref/source/mon-gear.cc:969
        -- Weapon list: crawl-ref/source/mon-gear.cc:969
        secondary = {
            weapons = {
                {
                    id = item_ids.WPN_SLING,
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
