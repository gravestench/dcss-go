-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:6576

local categories = require("constants.catalog")
local item_ids = require("ids.items")
local brands = require("constants.weapon_brands")

local definition = {
    id = "MONS_MENNAS",
    status = "defined",
    name = "Mennas",
    glyph = 65,
    colour_id = "LIGHTCYAN",
    flags = {
        "M_FIGHTER",
        "M_SPEAKS",
        "M_UNIQUE",
        "M_MALE",
        "M_FLIES",
    },
    resistances = {
        {
            id = "MR_RES_POISON",
            level = 1,
        },
        {
            id = "MR_RES_ELEC",
            level = 1,
        },
    },
    xp_modifier = 18,
    genus_id = "MONS_ANGEL",
    species_id = "MONS_ANGEL",
    holiness = {
        "MH_HOLY",
    },
    willpower = 160,
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 30,
        },
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 20,
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
    hd = 19,
    average_hp_10x = 1520,
    ac = 15,
    ev = 28,
    spellbook_id = "MST_MENNAS",
    shout_id = "S_SILENT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 15,
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
    shape_id = "MON_SHAPE_HUMANOID_WINGED",
    tile = {
        id = "TILEP_MONS_MENNAS",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
    weapon_gear = {
        -- Source: crawl-ref/source/mon-gear.cc:717
        -- Spec: crawl-ref/source/mon-gear.cc:717
        -- Weapon list: crawl-ref/source/mon-gear.cc:718
        -- Brand list: crawl-ref/source/mon-gear.cc:722
        primary = {
            weapons = {
                {
                    id = item_ids.WPN_TRISHULA,
                    weight = 1,
                },
                {
                    id = item_ids.WPN_SACRED_SCOURGE,
                    weight = 1,
                },
                {
                    id = item_ids.WPN_EUDEMON_BLADE,
                    weight = 1,
                },
            },
            plus = {
                odds = 1,
                min = 0,
                max = 5,
                rolls = 0,
            },
            brands = {
                {
                    id = brands.HOLY_WRATH,
                    weight = 1,
                },
            },
            good_chance = 0,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
