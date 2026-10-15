-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-prop.cc
-- Name Line: 457
-- Property Source: crawl-ref/source/item-prop.cc
-- Property Line: 457

local categories = require("constants.catalog")

local definition = {
    id = "WPN_DAGGER",
    name = "dagger",
    glyph = 41,
    class = "OBJ_WEAPONS",
    class_value = 0,
    subtype_value = 10,
    slot = "weapon",
    weapon_skill = "SK_SHORT_BLADES",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc:457
    naming = {
        text = "dagger",
        kind = "static",
    },
    explicitly_removed = false,
    weapon = {
        damage = 4,
        hit = 6,
        speed = 10,
        commonness = 10,
        acquire_weight = 10,
        price = 20,
        skill_id = "SK_SHORT_BLADES",
        min_2h_size_id = "SIZE_LITTLE",
        min_1h_size_id = "SIZE_LITTLE",
        ammo_id = "MI_NONE",
        damage_flags = {
            "DAMV_PIERCING",
        },
        brand_weights = {
            {
                brand_id = "SPWPN_VENOM",
                weight = 28,
            },
            {
                brand_id = "SPWPN_NORMAL",
                weight = 20,
            },
            {
                brand_id = "SPWPN_SPEED",
                weight = 10,
            },
            {
                brand_id = "SPWPN_DRAINING",
                weight = 9,
            },
            {
                brand_id = "SPWPN_PROTECTION",
                weight = 6,
            },
            {
                brand_id = "SPWPN_ELECTROCUTION",
                weight = 6,
            },
            {
                brand_id = "SPWPN_HOLY_WRATH",
                weight = 5,
            },
            {
                brand_id = "SPWPN_VAMPIRISM",
                weight = 4,
            },
            {
                brand_id = "SPWPN_FLAMING",
                weight = 4,
            },
            {
                brand_id = "SPWPN_FREEZING",
                weight = 4,
            },
            {
                brand_id = "SPWPN_PAIN",
                weight = 2,
            },
            {
                brand_id = "SPWPN_DISTORTION",
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
