-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:2942

local categories = require("constants.catalog")
local curves = require("constants.population_curves")
local item_ids = require("ids.items")

local definition = {
    id = "MONS_ETTIN",
    status = "defined",
    name = "ettin",
    glyph = 67,
    colour_id = "BROWN",
    flags = {
        "M_WARM_BLOOD",
        "M_TWO_WEAPONS",
        "M_SPEAKS",
    },
    xp_modifier = 12,
    genus_id = "MONS_GIANT",
    species_id = "MONS_ETTIN",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 40,
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 40,
        },
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 40,
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
    hd = 12,
    average_hp_10x = 660,
    ac = 9,
    ev = 4,
    spellbook_id = "MST_NO_SPELLS",
    leaves_corpse = true,
    shout_id = "S_SHOUT2",
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
        id = "TILEP_MONS_ETTIN",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_ETTIN",
    population = {
        -- Source line: 179
        {
            source_order = 110,
            min_depth = 21,
            max_depth = 31,
            rarity = 192,
            curve = curves.PEAK,
        },
    },
    weapon_gear = {
        -- Source: crawl-ref/source/mon-gear.cc:648
        -- Spec: crawl-ref/source/mon-gear.cc:649
        -- Weapon list: crawl-ref/source/mon-gear.cc:649
        primary = {
            weapons = {
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
