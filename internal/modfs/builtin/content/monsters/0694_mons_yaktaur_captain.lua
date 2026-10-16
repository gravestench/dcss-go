-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:488

local categories = require("constants.catalog")
local curves = require("constants.population_curves")
local item_ids = require("ids.items")

local definition = {
    id = "MONS_YAKTAUR_CAPTAIN",
    status = "defined",
    name = "yaktaur captain",
    glyph = 99,
    colour_id = "LIGHTRED",
    flags = {
        "M_WARM_BLOOD",
        "M_FIGHTER",
        "M_ARCHER",
        "M_SPEAKS",
    },
    xp_modifier = 9,
    genus_id = "MONS_YAKTAUR",
    species_id = "MONS_YAKTAUR",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 60,
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 30,
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
    average_hp_10x = 770,
    ac = 5,
    ev = 5,
    spellbook_id = "MST_NO_SPELLS",
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
    size_id = "SIZE_LARGE",
    shape_id = "MON_SHAPE_CENTAUR",
    tile = {
        id = "TILEP_MONS_YAKTAUR_CAPTAIN",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
    population = {
        -- Source line: 174
        {
            source_order = 105,
            min_depth = 20,
            max_depth = 30,
            rarity = 310,
            curve = curves.FALL,
        },
    },
    weapon_gear = {
        -- Source: crawl-ref/source/mon-gear.cc:685
        -- Spec: crawl-ref/source/mon-gear.cc:685
        -- Weapon list: crawl-ref/source/mon-gear.cc:685
        primary = {
            weapons = {
                {
                    id = item_ids.WPN_ARBALEST,
                    weight = 19,
                },
                {
                    id = item_ids.WPN_HAND_CROSSBOW,
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
