-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-prop.cc
-- Name Line: 567
-- Property Source: crawl-ref/source/item-prop.cc
-- Property Line: 567

local categories = require("constants.catalog")

local definition = {
    id = "WPN_TRIDENT",
    name = "trident",
    glyph = 41,
    class = "OBJ_WEAPONS",
    class_value = 0,
    subtype_value = 24,
    slot = "weapon",
    weapon_skill = "SK_POLEARMS",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc:567
    naming = {
        text = "trident",
        kind = "static",
    },
    explicitly_removed = false,
    weapon = {
        damage = 9,
        hit = 1,
        speed = 13,
        commonness = 6,
        acquire_weight = 10,
        price = 35,
        skill_id = "SK_POLEARMS",
        min_2h_size_id = "SIZE_LITTLE",
        min_1h_size_id = "SIZE_MEDIUM",
        ammo_id = "MI_NONE",
        damage_flags = {
            "DAMV_PIERCING",
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
