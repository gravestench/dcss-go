-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-prop.cc
-- Name Line: 491
-- Property Source: crawl-ref/source/item-prop.cc
-- Property Line: 491

local categories = require("constants.catalog")
local brands = require("constants.weapon_brands")

local definition = {
    id = "WPN_FALCHION",
    name = "falchion",
    glyph = 41,
    class = "OBJ_WEAPONS",
    class_value = 0,
    subtype_value = 14,
    slot = "weapon",
    weapon_skill = "SK_LONG_BLADES",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc:491
    naming = {
        text = "falchion",
        kind = "static",
    },
    explicitly_removed = false,
    weapon = {
        damage = 8,
        hit = 2,
        speed = 13,
        commonness = 7,
        acquire_weight = 10,
        price = 30,
        skill_id = "SK_LONG_BLADES",
        min_2h_size_id = "SIZE_LITTLE",
        min_1h_size_id = "SIZE_LITTLE",
        ammo_id = "MI_NONE",
        damage_flags = {
            "DAMV_SLICING",
        },
        brand_weights = {
            {
                brand_id = brands.HOLY_WRATH,
                weight = 23,
            },
            {
                brand_id = brands.NORMAL,
                weight = 19,
            },
            {
                brand_id = brands.VORPAL,
                weight = 15,
            },
            {
                brand_id = brands.ELECTROCUTION,
                weight = 10,
            },
            {
                brand_id = brands.PROTECTION,
                weight = 8,
            },
            {
                brand_id = brands.FREEZING,
                weight = 5,
            },
            {
                brand_id = brands.FLAMING,
                weight = 5,
            },
            {
                brand_id = brands.DRAINING,
                weight = 5,
            },
            {
                brand_id = brands.VAMPIRISM,
                weight = 4,
            },
            {
                brand_id = brands.VENOM,
                weight = 2,
            },
            {
                brand_id = brands.DISTORTION,
                weight = 2,
            },
            {
                brand_id = brands.PAIN,
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
        commonness = 7,
    },
}

register.definition(categories.ITEMS, definition)

return definition
