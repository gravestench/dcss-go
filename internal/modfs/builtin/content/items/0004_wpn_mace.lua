-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-prop.cc
-- Name Line: 399
-- Property Source: crawl-ref/source/item-prop.cc
-- Property Line: 399

local categories = require("constants.catalog")
local brands = require("constants.weapon_brands")

local definition = {
    id = "WPN_MACE",
    name = "mace",
    glyph = 41,
    class = "OBJ_WEAPONS",
    class_value = 0,
    subtype_value = 3,
    slot = "weapon",
    weapon_skill = "SK_MACES_FLAILS",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc:399
    naming = {
        text = "mace",
        kind = "static",
    },
    explicitly_removed = false,
    weapon = {
        damage = 8,
        hit = 3,
        speed = 14,
        commonness = 9,
        acquire_weight = 10,
        price = 30,
        skill_id = "SK_MACES_FLAILS",
        min_2h_size_id = "SIZE_LITTLE",
        min_1h_size_id = "SIZE_LITTLE",
        ammo_id = "MI_NONE",
        damage_flags = {
            "DAMV_CRUSHING",
        },
        brand_weights = {
            {
                brand_id = brands.PROTECTION,
                weight = 30,
            },
            {
                brand_id = brands.NORMAL,
                weight = 28,
            },
            {
                brand_id = brands.HOLY_WRATH,
                weight = 15,
            },
            {
                brand_id = brands.VORPAL,
                weight = 14,
            },
            {
                brand_id = brands.DRAINING,
                weight = 10,
            },
            {
                brand_id = brands.VENOM,
                weight = 5,
            },
            {
                brand_id = brands.DISTORTION,
                weight = 1,
            },
            {
                brand_id = brands.ANTIMAGIC,
                weight = 1,
            },
            {
                brand_id = brands.PAIN,
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
