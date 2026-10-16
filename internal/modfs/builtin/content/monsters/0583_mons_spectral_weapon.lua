-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mon-data.h:5423

local categories = require("constants.catalog")
local item_ids = require("ids.items")

local definition = {
    id = "MONS_SPECTRAL_WEAPON",
    status = "defined",
    name = "spectral weapon",
    glyph = 40,
    colour_id = "GREEN",
    flags = {
        "M_INSUBSTANTIAL",
        "M_NO_REGEN",
        "M_AVATAR",
        "M_NO_EXP_GAIN",
        "M_FLIES",
        "M_GHOST_DEMON",
        "M_UNBLINDABLE",
    },
    resistances = {
        {
            id = "MR_RES_FIRE",
            level = 1,
        },
        {
            id = "MR_RES_COLD",
            level = 1,
        },
        {
            id = "MR_RES_ELEC",
            level = 1,
        },
    },
    xp_modifier = 11,
    genus_id = "MONS_WRAITH",
    species_id = "MONS_SPECTRAL_WEAPON",
    holiness = {
        "MH_NONLIVING",
    },
    willpower = 5000,
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 6,
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
    hd = 5,
    average_hp_10x = 250,
    ac = 5,
    ev = 10,
    spellbook_id = "MST_NO_SPELLS",
    shout_id = "S_SILENT",
    intelligence_id = "I_BRAINLESS",
    habitat_id = "HT_LAND",
    speed = 30,
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
    item_use_id = "MONUSE_NOTHING",
    size_id = "SIZE_MEDIUM",
    shape_id = "MON_SHAPE_MISC",
    tile = {
        id = "TILEP_MONS_SPECTRAL_SBL",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
    weapon_gear = {
        -- Source: crawl-ref/source/mon-gear.cc:575
        -- Spec: crawl-ref/source/mon-gear.cc:575
        -- Weapon list: crawl-ref/source/mon-gear.cc:331
        primary = {
            weapons = {
                {
                    id = item_ids.WPN_LONG_SWORD,
                    weight = 10,
                },
                {
                    id = item_ids.WPN_SHORT_SWORD,
                    weight = 10,
                },
                {
                    id = item_ids.WPN_SCIMITAR,
                    weight = 10,
                },
                {
                    id = item_ids.WPN_BATTLEAXE,
                    weight = 10,
                },
                {
                    id = item_ids.WPN_HAND_AXE,
                    weight = 10,
                },
                {
                    id = item_ids.WPN_HALBERD,
                    weight = 10,
                },
                {
                    id = item_ids.WPN_GLAIVE,
                    weight = 10,
                },
                {
                    id = item_ids.WPN_MACE,
                    weight = 10,
                },
                {
                    id = item_ids.WPN_DIRE_FLAIL,
                    weight = 10,
                },
                {
                    id = item_ids.WPN_TRIDENT,
                    weight = 10,
                },
                {
                    id = item_ids.WPN_WAR_AXE,
                    weight = 9,
                },
                {
                    id = item_ids.WPN_FLAIL,
                    weight = 9,
                },
                {
                    id = item_ids.WPN_BROAD_AXE,
                    weight = 1,
                },
                {
                    id = item_ids.WPN_MORNINGSTAR,
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
