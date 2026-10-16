-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-prop.cc
-- Name Line: 609
-- Property Source: crawl-ref/source/item-prop.cc
-- Property Line: 609

local categories = require("constants.catalog")
local brands = require("constants.weapon_brands")

local definition = {
    id = "WPN_LAJATANG",
    name = "lajatang",
    glyph = 41,
    class = "OBJ_WEAPONS",
    class_value = 0,
    subtype_value = 42,
    slot = "weapon",
    weapon_skill = "SK_STAVES",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc:609
    naming = {
        text = "lajatang",
        kind = "static",
    },
    explicitly_removed = false,
    weapon = {
        damage = 16,
        hit = -3,
        speed = 14,
        commonness = 2,
        acquire_weight = 2,
        price = 150,
        skill_id = "SK_STAVES",
        min_2h_size_id = "SIZE_LITTLE",
        min_1h_size_id = "NUM_SIZE_LEVELS",
        ammo_id = "MI_NONE",
        damage_flags = {
            "DAMV_SLICING",
        },
        brand_weights = {
            {
                brand_id = brands.NORMAL,
                weight = 34,
            },
            {
                brand_id = brands.SPEED,
                weight = 12,
            },
            {
                brand_id = brands.ELECTROCUTION,
                weight = 12,
            },
            {
                brand_id = brands.VAMPIRISM,
                weight = 12,
            },
            {
                brand_id = brands.SPECTRAL,
                weight = 9,
            },
            {
                brand_id = brands.VENOM,
                weight = 7,
            },
            {
                brand_id = brands.PAIN,
                weight = 7,
            },
            {
                brand_id = brands.ANTIMAGIC,
                weight = 4,
            },
            {
                brand_id = brands.DISTORTION,
                weight = 3,
            },
        },
    },
    -- Source: crawl-ref/source/item-prop.cc
    generation = {
        mode = "random",
        commonness = 2,
    },
}

register.definition(categories.ITEMS, definition)

return definition
