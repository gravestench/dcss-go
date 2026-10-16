-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:786

local categories = require("constants.catalog")
local item_ids = require("ids.items")

local definition = {
    id = "MONS_DEEP_ELF_BLADEMASTER",
    status = "defined",
    name = "deep elf blademaster",
    glyph = 101,
    colour_id = "LIGHTCYAN",
    flags = {
        "M_WARM_BLOOD",
        "M_FIGHTER",
        "M_TWO_WEAPONS",
        "M_SPEAKS",
    },
    xp_modifier = 10,
    genus_id = "MONS_ELF",
    species_id = "MONS_ELF",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 120,
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 25,
        },
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 25,
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
    average_hp_10x = 1040,
    ev = 25,
    spellbook_id = "MST_NO_SPELLS",
    leaves_corpse = true,
    shout_id = "S_SHOUT",
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
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_DEEP_ELF_BLADEMASTER",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
    weapon_gear = {
        -- Source: crawl-ref/source/mon-gear.cc:545
        -- Spec: crawl-ref/source/mon-gear.cc:546
        -- Weapon list: crawl-ref/source/mon-gear.cc:546
        primary = {
            weapons = {
                {
                    id = item_ids.WPN_RAPIER,
                    weight = 20,
                },
                {
                    id = item_ids.WPN_SHORT_SWORD,
                    weight = 5,
                },
                {
                    id = item_ids.WPN_QUICK_BLADE,
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
