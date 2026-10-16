-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-prop.cc
-- Name Line: 509
-- Property Source: crawl-ref/source/item-prop.cc
-- Property Line: 509

local categories = require("constants.catalog")
local brands = require("constants.weapon_brands")

local definition = {
    id = "WPN_GREAT_SWORD",
    name = "great sword",
    glyph = 41,
    class = "OBJ_WEAPONS",
    class_value = 0,
    subtype_value = 17,
    slot = "weapon",
    weapon_skill = "SK_LONG_BLADES",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc:509
    naming = {
        text = "great sword",
        kind = "static",
    },
    explicitly_removed = false,
    weapon = {
        damage = 17,
        hit = -3,
        speed = 17,
        commonness = 6,
        acquire_weight = 10,
        price = 65,
        skill_id = "SK_LONG_BLADES",
        min_2h_size_id = "SIZE_MEDIUM",
        min_1h_size_id = "NUM_SIZE_LEVELS",
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
        commonness = 6,
    },
}

register.definition(categories.ITEMS, definition)

return definition
