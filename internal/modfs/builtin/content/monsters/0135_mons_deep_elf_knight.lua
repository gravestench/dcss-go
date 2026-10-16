-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:760

local categories = require("constants.catalog")
local curves = require("constants.population_curves")
local item_ids = require("ids.items")

local definition = {
    id = "MONS_DEEP_ELF_KNIGHT",
    status = "defined",
    name = "deep elf knight",
    glyph = 101,
    colour_id = "BLUE",
    flags = {
        "M_WARM_BLOOD",
        "M_FIGHTER",
        "M_SPEAKS",
    },
    xp_modifier = 10,
    genus_id = "MONS_ELF",
    species_id = "MONS_ELF",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 80,
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 21,
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
    hd = 11,
    average_hp_10x = 495,
    ev = 17,
    spellbook_id = "MST_DEEP_ELF_KNIGHT",
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
        id = "TILEP_MONS_DEEP_ELF_KNIGHT",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
    population = {
        -- Source line: 163
        {
            source_order = 94,
            min_depth = 17,
            max_depth = 25,
            rarity = 136,
            curve = curves.SEMI,
        },
    },
    weapon_gear = {
        -- Source: crawl-ref/source/mon-gear.cc:543
        -- Spec: crawl-ref/source/mon-gear.cc:543
        -- Weapon list: crawl-ref/source/mon-gear.cc:314
        primary = {
            weapons = {
                {
                    id = item_ids.WPN_LONG_SWORD,
                    weight = 22,
                },
                {
                    id = item_ids.WPN_SHORT_SWORD,
                    weight = 22,
                },
                {
                    id = item_ids.WPN_SCIMITAR,
                    weight = 17,
                },
                {
                    id = item_ids.WPN_SHORTBOW,
                    weight = 17,
                },
                {
                    id = item_ids.WPN_LONGBOW,
                    weight = 5,
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
