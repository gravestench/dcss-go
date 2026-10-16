-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-prop.cc
-- Name Line: 477
-- Property Source: crawl-ref/source/item-prop.cc
-- Property Line: 477

local categories = require("constants.catalog")
local brands = require("constants.weapon_brands")

local definition = {
    id = "WPN_SHORT_SWORD",
    name = "short sword",
    glyph = 41,
    class = "OBJ_WEAPONS",
    class_value = 0,
    subtype_value = 12,
    slot = "weapon",
    weapon_skill = "SK_SHORT_BLADES",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc:477
    naming = {
        text = "short sword",
        kind = "static",
    },
    explicitly_removed = false,
    weapon = {
        damage = 5,
        hit = 4,
        speed = 11,
        commonness = 8,
        acquire_weight = 10,
        price = 30,
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
