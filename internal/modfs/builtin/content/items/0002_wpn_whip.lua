-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-prop.cc
-- Name Line: 379
-- Property Source: crawl-ref/source/item-prop.cc
-- Property Line: 379

local categories = require("constants.catalog")
local brands = require("constants.weapon_brands")

local definition = {
    id = "WPN_WHIP",
    name = "whip",
    glyph = 41,
    class = "OBJ_WEAPONS",
    class_value = 0,
    subtype_value = 1,
    slot = "weapon",
    weapon_skill = "SK_MACES_FLAILS",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc:379
    naming = {
        text = "whip",
        kind = "static",
    },
    explicitly_removed = false,
    weapon = {
        damage = 6,
        hit = 2,
        speed = 11,
        commonness = 4,
        acquire_weight = 0,
        price = 25,
        skill_id = "SK_MACES_FLAILS",
        min_2h_size_id = "SIZE_LITTLE",
        min_1h_size_id = "SIZE_LITTLE",
        ammo_id = "MI_NONE",
        damage_flags = {
            "DAMV_SLASHING",
        },
        brand_weights = {
            {
                brand_id = brands.NORMAL,
                weight = 34,
            },
            {
                brand_id = brands.VENOM,
                weight = 16,
            },
            {
                brand_id = brands.ELECTROCUTION,
                weight = 16,
            },
            {
                brand_id = brands.DRAINING,
                weight = 7,
            },
            {
                brand_id = brands.FREEZING,
                weight = 6,
            },
            {
                brand_id = brands.FLAMING,
                weight = 6,
            },
            {
                brand_id = brands.VAMPIRISM,
                weight = 5,
            },
            {
                brand_id = brands.PAIN,
                weight = 4,
            },
            {
                brand_id = brands.HOLY_WRATH,
                weight = 3,
            },
            {
                brand_id = brands.DISTORTION,
                weight = 2,
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
        commonness = 4,
    },
}

register.definition(categories.ITEMS, definition)

return definition
