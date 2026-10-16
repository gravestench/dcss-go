-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:773

local categories = require("constants.catalog")
local curves = require("constants.population_curves")
local item_ids = require("ids.items")

local definition = {
    id = "MONS_DEEP_ELF_ARCHER",
    status = "defined",
    name = "deep elf archer",
    glyph = 101,
    colour_id = "BROWN",
    flags = {
        "M_WARM_BLOOD",
        "M_ARCHER",
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
    hd = 10,
    average_hp_10x = 500,
    ev = 15,
    spellbook_id = "MST_DEEP_ELF_ARCHER",
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
        id = "TILEP_MONS_DEEP_ELF_ARCHER",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
    population = {
        -- Source line: 164
        {
            source_order = 95,
            min_depth = 17,
            max_depth = 25,
            rarity = 136,
            curve = curves.SEMI,
        },
    },
    weapon_gear = {
        -- Source: crawl-ref/source/mon-gear.cc:550
        -- Spec: crawl-ref/source/mon-gear.cc:551
        -- Weapon list: crawl-ref/source/mon-gear.cc:551
        primary = {
            weapons = {
                {
                    id = item_ids.WPN_SHORT_SWORD,
                    weight = 1,
                },
                {
                    id = item_ids.WPN_DAGGER,
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
        -- Source: crawl-ref/source/mon-gear.cc:941
        -- Spec: crawl-ref/source/mon-gear.cc:942
        -- Weapon list: crawl-ref/source/mon-gear.cc:942
        secondary = {
            weapons = {
                {
                    id = item_ids.WPN_SHORTBOW,
                    weight = 3,
                },
                {
                    id = item_ids.WPN_LONGBOW,
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
