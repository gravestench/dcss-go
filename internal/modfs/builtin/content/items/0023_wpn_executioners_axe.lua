-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-prop.cc
-- Name Line: 549
-- Property Source: crawl-ref/source/item-prop.cc
-- Property Line: 549

local categories = require("constants.catalog")
local brands = require("constants.weapon_brands")

local definition = {
    id = "WPN_EXECUTIONERS_AXE",
    name = "executioner's axe",
    glyph = 41,
    class = "OBJ_WEAPONS",
    class_value = 0,
    subtype_value = 22,
    slot = "weapon",
    weapon_skill = "SK_AXES",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc:549
    naming = {
        text = "executioner's axe",
        kind = "static",
    },
    explicitly_removed = false,
    weapon = {
        damage = 18,
        hit = -6,
        speed = 19,
        commonness = 0,
        acquire_weight = 2,
        price = 100,
        skill_id = "SK_AXES",
        min_2h_size_id = "SIZE_MEDIUM",
        min_1h_size_id = "NUM_SIZE_LEVELS",
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
        commonness = 0,
    },
}

register.definition(categories.ITEMS, definition)

return definition
