-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-prop.cc
-- Name Line: 587
-- Property Source: crawl-ref/source/item-prop.cc
-- Property Line: 587

local categories = require("constants.catalog")
local brands = require("constants.weapon_brands")

local definition = {
    id = "WPN_BARDICHE",
    name = "bardiche",
    glyph = 41,
    class = "OBJ_WEAPONS",
    class_value = 0,
    subtype_value = 27,
    slot = "weapon",
    weapon_skill = "SK_POLEARMS",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc:587
    naming = {
        text = "bardiche",
        kind = "static",
    },
    explicitly_removed = false,
    weapon = {
        damage = 18,
        hit = -6,
        speed = 19,
        commonness = 1,
        acquire_weight = 2,
        price = 90,
        skill_id = "SK_POLEARMS",
        min_2h_size_id = "SIZE_MEDIUM",
        min_1h_size_id = "NUM_SIZE_LEVELS",
        ammo_id = "MI_NONE",
        damage_flags = {
            "DAMV_CHOPPING",
        },
        brand_weights = {
            {
                brand_id = brands.NORMAL,
                weight = 36,
            },
            {
                brand_id = brands.VENOM,
                weight = 17,
            },
            {
                brand_id = brands.PROTECTION,
                weight = 12,
            },
            {
                brand_id = brands.VORPAL,
                weight = 9,
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
            {
                brand_id = brands.HOLY_WRATH,
                weight = 1,
            },
        },
    },
    -- Source: crawl-ref/source/item-prop.cc
    generation = {
        mode = "random",
        commonness = 1,
    },
}

register.definition(categories.ITEMS, definition)

return definition
