-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-prop.cc
-- Name Line: 537
-- Property Source: crawl-ref/source/item-prop.cc
-- Property Line: 537

local categories = require("constants.catalog")
local brands = require("constants.weapon_brands")

local definition = {
    id = "WPN_HAND_AXE",
    name = "hand axe",
    glyph = 41,
    class = "OBJ_WEAPONS",
    class_value = 0,
    subtype_value = 18,
    slot = "weapon",
    weapon_skill = "SK_AXES",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc:537
    naming = {
        text = "hand axe",
        kind = "static",
    },
    explicitly_removed = false,
    weapon = {
        damage = 7,
        hit = 3,
        speed = 13,
        commonness = 9,
        acquire_weight = 10,
        price = 30,
        skill_id = "SK_AXES",
        min_2h_size_id = "SIZE_LITTLE",
        min_1h_size_id = "SIZE_LITTLE",
        ammo_id = "MI_NONE",
        damage_flags = {
            "DAMV_CHOPPING",
        },
        brand_weights = {
            {
                brand_id = brands.NORMAL,
                weight = 31,
            },
            {
                brand_id = brands.VORPAL,
                weight = 16,
            },
            {
                brand_id = brands.ELECTROCUTION,
                weight = 11,
            },
            {
                brand_id = brands.FLAMING,
                weight = 10,
            },
            {
                brand_id = brands.FREEZING,
                weight = 10,
            },
            {
                brand_id = brands.VENOM,
                weight = 8,
            },
            {
                brand_id = brands.VAMPIRISM,
                weight = 5,
            },
            {
                brand_id = brands.DRAINING,
                weight = 3,
            },
            {
                brand_id = brands.DISTORTION,
                weight = 2,
            },
            {
                brand_id = brands.ANTIMAGIC,
                weight = 2,
            },
            {
                brand_id = brands.PAIN,
                weight = 1,
            },
            {
                brand_id = brands.HOLY_WRATH,
                weight = 1,
            },
        },
    },
    -- Source: crawl-ref/source/item-prop.cc
    generation = {
        mode = "random",
        commonness = 9,
    },
}

register.definition(categories.ITEMS, definition)

return definition
