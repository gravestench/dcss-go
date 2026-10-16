-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-prop.cc
-- Name Line: 554
-- Property Source: crawl-ref/source/item-prop.cc
-- Property Line: 554

local categories = require("constants.catalog")
local brands = require("constants.weapon_brands")

local definition = {
    id = "WPN_SPEAR",
    name = "spear",
    glyph = 41,
    class = "OBJ_WEAPONS",
    class_value = 0,
    subtype_value = 23,
    slot = "weapon",
    weapon_skill = "SK_POLEARMS",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc:554
    naming = {
        text = "spear",
        kind = "static",
    },
    explicitly_removed = false,
    weapon = {
        damage = 6,
        hit = 4,
        speed = 11,
        commonness = 8,
        acquire_weight = 10,
        price = 30,
        skill_id = "SK_POLEARMS",
        min_2h_size_id = "SIZE_LITTLE",
        min_1h_size_id = "SIZE_LITTLE",
        ammo_id = "MI_NONE",
        damage_flags = {
            "DAMV_PIERCING",
        },
        brand_weights = {
            {
                brand_id = brands.NORMAL,
                weight = 46,
            },
            {
                brand_id = brands.VENOM,
                weight = 17,
            },
            {
                brand_id = brands.VORPAL,
                weight = 12,
            },
            {
                brand_id = brands.FLAMING,
                weight = 7,
            },
            {
                brand_id = brands.FREEZING,
                weight = 7,
            },
            {
                brand_id = brands.VAMPIRISM,
                weight = 5,
            },
            {
                brand_id = brands.DISTORTION,
                weight = 2,
            },
            {
                brand_id = brands.PAIN,
                weight = 2,
            },
            {
                brand_id = brands.ANTIMAGIC,
                weight = 2,
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
