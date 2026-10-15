-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-prop.cc
-- Name Line: 570
-- Property Source: crawl-ref/source/item-prop.cc
-- Property Line: 570

local categories = require("constants.catalog")

local definition = {
    id = "WPN_HALBERD",
    name = "halberd",
    glyph = 41,
    class = "OBJ_WEAPONS",
    class_value = 0,
    subtype_value = 25,
    slot = "weapon",
    weapon_skill = "SK_POLEARMS",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc:570
    naming = {
        text = "halberd",
        kind = "static",
    },
    explicitly_removed = false,
    weapon = {
        damage = 13,
        hit = -3,
        speed = 15,
        commonness = 5,
        acquire_weight = 10,
        price = 40,
        skill_id = "SK_POLEARMS",
        min_2h_size_id = "SIZE_MEDIUM",
        min_1h_size_id = "NUM_SIZE_LEVELS",
        ammo_id = "MI_NONE",
        damage_flags = {
            "DAMV_CHOPPING",
            "DAM_PIERCE",
        },
        brand_weights = {
            {
                brand_id = "SPWPN_NORMAL",
                weight = 36,
            },
            {
                brand_id = "SPWPN_VENOM",
                weight = 17,
            },
            {
                brand_id = "SPWPN_PROTECTION",
                weight = 12,
            },
            {
                brand_id = "SPWPN_VORPAL",
                weight = 9,
            },
            {
                brand_id = "SPWPN_FLAMING",
                weight = 7,
            },
            {
                brand_id = "SPWPN_FREEZING",
                weight = 7,
            },
            {
                brand_id = "SPWPN_VAMPIRISM",
                weight = 5,
            },
            {
                brand_id = "SPWPN_DISTORTION",
                weight = 2,
            },
            {
                brand_id = "SPWPN_PAIN",
                weight = 2,
            },
            {
                brand_id = "SPWPN_ANTIMAGIC",
                weight = 2,
            },
            {
                brand_id = "SPWPN_HOLY_WRATH",
                weight = 1,
            },
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition
