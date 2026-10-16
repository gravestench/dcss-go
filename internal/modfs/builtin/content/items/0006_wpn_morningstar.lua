-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-prop.cc
-- Name Line: 405
-- Property Source: crawl-ref/source/item-prop.cc
-- Property Line: 405

local categories = require("constants.catalog")
local brands = require("constants.weapon_brands")

local definition = {
    id = "WPN_MORNINGSTAR",
    name = "morningstar",
    glyph = 41,
    class = "OBJ_WEAPONS",
    class_value = 0,
    subtype_value = 5,
    slot = "weapon",
    weapon_skill = "SK_MACES_FLAILS",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc:405
    naming = {
        text = "morningstar",
        kind = "static",
    },
    explicitly_removed = false,
    weapon = {
        damage = 13,
        hit = -2,
        speed = 15,
        commonness = 7,
        acquire_weight = 10,
        price = 40,
        skill_id = "SK_MACES_FLAILS",
        min_2h_size_id = "SIZE_LITTLE",
        min_1h_size_id = "SIZE_LITTLE",
        ammo_id = "MI_NONE",
        damage_flags = {
            "DAMV_CRUSHING",
            "DAM_PIERCE",
        },
        brand_weights = {
            {
                brand_id = brands.PROTECTION,
                weight = 30,
            },
            {
                brand_id = brands.NORMAL,
                weight = 15,
            },
            {
                brand_id = brands.HOLY_WRATH,
                weight = 15,
            },
            {
                brand_id = brands.DRAINING,
                weight = 10,
            },
            {
                brand_id = brands.VORPAL,
                weight = 9,
            },
            {
                brand_id = brands.VENOM,
                weight = 5,
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
                weight = 2,
            },
            {
                brand_id = brands.ANTIMAGIC,
                weight = 2,
            },
            {
                brand_id = brands.PAIN,
                weight = 2,
            },
            {
                brand_id = brands.VAMPIRISM,
                weight = 2,
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
