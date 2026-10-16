-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:6677

local categories = require("constants.catalog")
local item_ids = require("ids.items")

local definition = {
    id = "MONS_BAI_SUZHEN",
    status = "defined",
    name = "Bai Suzhen",
    glyph = 100,
    colour_id = "LIGHTBLUE",
    flags = {
        "M_UNIQUE",
        "M_SEE_INVIS",
        "M_COLD_BLOOD",
        "M_SPEAKS",
        "M_FEMALE",
    },
    resistances = {
        {
            id = "MR_RES_ELEC",
            level = 3,
        },
        {
            id = "MR_RES_COLD",
            level = 1,
        },
        {
            id = "MR_RES_POISON",
            level = 1,
        },
    },
    xp_modifier = 16,
    genus_id = "MONS_DRAGON",
    species_id = "MONS_STORM_DRAGON",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 100,
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 24,
        },
        {
            type_id = "AT_TAIL_SLAP",
            flavour_id = "AF_PLAIN",
            damage = 14,
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
    hd = 20,
    average_hp_10x = 1850,
    ac = 14,
    ev = 8,
    spellbook_id = "MST_BAI_SUZHEN",
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
        id = "TILEP_MONS_BAI_SUZHEN",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
    weapon_gear = {
        -- Source: crawl-ref/source/mon-gear.cc:505
        -- Spec: crawl-ref/source/mon-gear.cc:505
        -- Weapon list: crawl-ref/source/mon-gear.cc:505
        primary = {
            weapons = {
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
    },
}

register.definition(categories.MONSTERS, definition)

return definition
