-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-prop.cc
-- Name Line: 480
-- Property Source: crawl-ref/source/item-prop.cc
-- Property Line: 480

local categories = require("constants.catalog")
local brands = require("constants.weapon_brands")

local definition = {
    id = "WPN_RAPIER",
    name = "rapier",
    glyph = 41,
    class = "OBJ_WEAPONS",
    class_value = 0,
    subtype_value = 13,
    slot = "weapon",
    weapon_skill = "SK_SHORT_BLADES",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc:480
    naming = {
        text = "rapier",
        kind = "static",
    },
    explicitly_removed = false,
    weapon = {
        damage = 7,
        hit = 4,
        speed = 12,
        commonness = 8,
        acquire_weight = 10,
        price = 40,
        skill_id = "SK_SHORT_BLADES",
        min_2h_size_id = "SIZE_LITTLE",
        min_1h_size_id = "SIZE_LITTLE",
        ammo_id = "MI_NONE",
        damage_flags = {
            "DAMV_PIERCING",
        },
        brand_weights = {
            {
                brand_id = brands.NORMAL,
                weight = 33,
            },
            {
                brand_id = brands.VENOM,
                weight = 17,
            },
            {
                brand_id = brands.SPEED,
                weight = 10,
            },
            {
                brand_id = brands.DRAINING,
                weight = 9,
            },
            {
                brand_id = brands.PROTECTION,
                weight = 6,
            },
            {
                brand_id = brands.ELECTROCUTION,
                weight = 6,
            },
            {
                brand_id = brands.HOLY_WRATH,
                weight = 5,
            },
            {
                brand_id = brands.VAMPIRISM,
                weight = 4,
            },
            {
                brand_id = brands.FLAMING,
                weight = 4,
            },
            {
                brand_id = brands.FREEZING,
                weight = 4,
            },
            {
                brand_id = brands.DISTORTION,
                weight = 1,
            },
            {
                brand_id = brands.ANTIMAGIC,
                weight = 1,
            },
        },
    },
    -- Source: crawl-ref/source/item-prop.cc
    generation = {
        mode = "random",
        commonness = 8,
    },
}

register.definition(categories.ITEMS, definition)

return definition
