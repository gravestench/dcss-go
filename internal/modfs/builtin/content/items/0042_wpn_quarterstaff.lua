-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-prop.cc
-- Name Line: 596
-- Property Source: crawl-ref/source/item-prop.cc
-- Property Line: 596

local categories = require("constants.catalog")
local brands = require("constants.weapon_brands")

local definition = {
    id = "WPN_QUARTERSTAFF",
    name = "quarterstaff",
    glyph = 41,
    class = "OBJ_WEAPONS",
    class_value = 0,
    subtype_value = 41,
    slot = "weapon",
    weapon_skill = "SK_STAVES",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc:596
    naming = {
        text = "quarterstaff",
        kind = "static",
    },
    explicitly_removed = false,
    weapon = {
        damage = 10,
        hit = 3,
        speed = 13,
        commonness = 8,
        acquire_weight = 10,
        price = 40,
        skill_id = "SK_STAVES",
        min_2h_size_id = "SIZE_LITTLE",
        min_1h_size_id = "NUM_SIZE_LEVELS",
        ammo_id = "MI_NONE",
        damage_flags = {
            "DAMV_CRUSHING",
        },
        brand_weights = {
            {
                brand_id = brands.NORMAL,
                weight = 50,
            },
            {
                brand_id = brands.SPECTRAL,
                weight = 18,
            },
            {
                brand_id = brands.DRAINING,
                weight = 8,
            },
            {
                brand_id = brands.VORPAL,
                weight = 8,
            },
            {
                brand_id = brands.SPEED,
                weight = 8,
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
                brand_id = brands.HOLY_WRATH,
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
