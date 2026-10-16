-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:5297

local categories = require("constants.catalog")
local item_ids = require("ids.items")

local definition = {
    id = "MONS_SALAMANDER",
    status = "defined",
    name = "salamander",
    glyph = 78,
    colour_id = "LIGHTRED",
    flags = {
        "M_FIGHTER",
        "M_WARM_BLOOD",
    },
    resistances = {
        {
            id = "MR_RES_FIRE",
            level = 3,
        },
        {
            id = "MR_RES_COLD",
            level = -1,
        },
    },
    xp_modifier = 10,
    genus_id = "MONS_NAGA",
    species_id = "MONS_SALAMANDER",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 40,
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_FIRE",
            damage = 17,
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
    hd = 8,
    average_hp_10x = 640,
    ac = 5,
    ev = 7,
    spellbook_id = "MST_NO_SPELLS",
    leaves_corpse = true,
    shout_id = "S_SILENT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_AMPHIBIOUS_LAVA",
    speed = 10,
    energy = {
        move = 10,
        swim = 7,
        attack = 10,
        missile = 10,
        spell = 10,
        special = 10,
        item = 10,
        pickup_percent = 100,
    },
    item_use_id = "MONUSE_WEAPONS_ARMOUR",
    size_id = "SIZE_MEDIUM",
    shape_id = "MON_SHAPE_NAGA",
    tile = {
        id = "TILEP_MONS_SALAMANDER",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_SALAMANDER",
    weapon_gear = {
        -- Source: crawl-ref/source/mon-gear.cc:977
        -- Spec: crawl-ref/source/mon-gear.cc:977
        -- Weapon list: crawl-ref/source/mon-gear.cc:978
        secondary = {
            weapons = {
                {
                    id = item_ids.WPN_HALBERD,
                    weight = 5,
                },
                {
                    id = item_ids.WPN_TRIDENT,
                    weight = 5,
                },
                {
                    id = item_ids.WPN_SPEAR,
                    weight = 3,
                },
                {
                    id = item_ids.WPN_GLAIVE,
                    weight = 2,
                },
                {
                    id = item_ids.WPN_SHORTBOW,
                    weight = 5,
                },
            },
            plus = {
                odds = 4,
                min = 0,
                max = 4,
                rolls = 0,
            },
            brands = mod.null,
            good_chance = 0,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
