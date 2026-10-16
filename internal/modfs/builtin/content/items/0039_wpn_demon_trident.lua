-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-prop.cc
-- Name Line: 578
-- Property Source: crawl-ref/source/item-prop.cc
-- Property Line: 578

local categories = require("constants.catalog")
local brands = require("constants.weapon_brands")

local definition = {
    id = "WPN_DEMON_TRIDENT",
    name = "demon trident",
    glyph = 41,
    class = "OBJ_WEAPONS",
    class_value = 0,
    subtype_value = 38,
    slot = "weapon",
    weapon_skill = "SK_POLEARMS",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc:578
    naming = {
        text = "demon trident",
        kind = "static",
    },
    explicitly_removed = false,
    weapon = {
        damage = 12,
        hit = 1,
        speed = 13,
        commonness = 0,
        acquire_weight = 2,
        price = 150,
        skill_id = "SK_POLEARMS",
        min_2h_size_id = "SIZE_LITTLE",
        min_1h_size_id = "SIZE_MEDIUM",
        ammo_id = "MI_NONE",
        damage_flags = {
            "DAMV_PIERCING",
        },
        brand_weights = {
            {
                brand_id = brands.NORMAL,
                weight = 27,
            },
            {
                brand_id = brands.VENOM,
                weight = 19,
            },
            {
                brand_id = brands.ELECTROCUTION,
                weight = 16,
            },
            {
                brand_id = brands.DRAINING,
                weight = 10,
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
                weight = 7,
            },
            {
                brand_id = brands.PAIN,
                weight = 4,
            },
            {
                brand_id = brands.ANTIMAGIC,
                weight = 3,
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
