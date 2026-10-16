-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:2814

local categories = require("constants.catalog")
local item_ids = require("ids.items")

local definition = {
    id = "MONS_PROFANE_SERVITOR",
    status = "defined",
    name = "profane servitor",
    glyph = 65,
    colour_id = "RED",
    flags = {
        "M_FIGHTER",
        "M_SEE_INVIS",
        "M_SPEAKS",
        "M_FLIES",
    },
    resistances = {
        {
            id = "MR_RES_COLD",
            level = 1,
        },
        {
            id = "MR_RES_ELEC",
            level = 1,
        },
    },
    xp_modifier = 10,
    genus_id = "MONS_ANGEL",
    species_id = "MONS_PROFANE_SERVITOR",
    holiness = {
        "MH_UNDEAD",
    },
    willpower = 140,
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_VAMPIRIC",
            damage = 25,
        },
        {
            type_id = "AT_HIT",
            flavour_id = "AF_DRAIN",
            damage = 10,
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
    hd = 18,
    average_hp_10x = 1530,
    ac = 10,
    ev = 20,
    spellbook_id = "MST_NO_SPELLS",
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
    item_use_id = "MONUSE_STARTING_EQUIPMENT",
    size_id = "SIZE_MEDIUM",
    shape_id = "MON_SHAPE_HUMANOID_WINGED",
    tile = {
        id = "TILEP_MONS_PROFANE_SERVITOR",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
    weapon_gear = {
        -- Source: crawl-ref/source/mon-gear.cc:712
        -- Spec: crawl-ref/source/mon-gear.cc:713
        -- Weapon list: crawl-ref/source/mon-gear.cc:713
        primary = {
            weapons = {
                {
                    id = item_ids.WPN_DEMON_WHIP,
                    weight = 1,
                },
                {
                    id = item_ids.WPN_WHIP,
                    weight = 3,
                },
            },
            plus = {
                odds = 1,
                min = 1,
                max = 3,
                rolls = 0,
            },
            brands = mod.null,
            good_chance = 0,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
