-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-prop.cc
-- Name Line: 497
-- Property Source: crawl-ref/source/item-prop.cc
-- Property Line: 497

local categories = require("constants.catalog")

local definition = {
    id = "WPN_SCIMITAR",
    name = "scimitar",
    glyph = 41,
    class = "OBJ_WEAPONS",
    class_value = 0,
    subtype_value = 16,
    slot = "weapon",
    weapon_skill = "SK_LONG_BLADES",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc:497
    naming = {
        text = "scimitar",
        kind = "static",
    },
    explicitly_removed = false,
    weapon = {
        damage = 12,
        hit = 0,
        speed = 14,
        commonness = 6,
        acquire_weight = 10,
        price = 40,
        skill_id = "SK_LONG_BLADES",
        min_2h_size_id = "SIZE_LITTLE",
        min_1h_size_id = "SIZE_LITTLE",
        ammo_id = "MI_NONE",
        damage_flags = {
            "DAMV_SLICING",
        },
        brand_weights = {
            {
                brand_id = "SPWPN_HOLY_WRATH",
                weight = 23,
            },
            {
                brand_id = "SPWPN_NORMAL",
                weight = 19,
            },
            {
                brand_id = "SPWPN_VORPAL",
                weight = 15,
            },
            {
                brand_id = "SPWPN_ELECTROCUTION",
                weight = 10,
            },
            {
                brand_id = "SPWPN_PROTECTION",
                weight = 8,
            },
            {
                brand_id = "SPWPN_FREEZING",
                weight = 5,
            },
            {
                brand_id = "SPWPN_FLAMING",
                weight = 5,
            },
            {
                brand_id = "SPWPN_DRAINING",
                weight = 5,
            },
            {
                brand_id = "SPWPN_VAMPIRISM",
                weight = 4,
            },
            {
                brand_id = "SPWPN_VENOM",
                weight = 2,
            },
            {
                brand_id = "SPWPN_DISTORTION",
                weight = 2,
            },
            {
                brand_id = "SPWPN_PAIN",
                weight = 1,
            },
            {
                brand_id = "SPWPN_ANTIMAGIC",
                weight = 1,
            },
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition
