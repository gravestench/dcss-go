-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-prop.cc
-- Name Line: 371
-- Property Source: crawl-ref/source/item-prop.cc
-- Property Line: 371

local categories = require("constants.catalog")
local brands = require("constants.weapon_brands")

local definition = {
    id = "WPN_CLUB",
    name = "club",
    glyph = 41,
    class = "OBJ_WEAPONS",
    class_value = 0,
    subtype_value = 0,
    slot = "weapon",
    weapon_skill = "SK_MACES_FLAILS",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc:371
    naming = {
        text = "club",
        kind = "static",
    },
    explicitly_removed = false,
    weapon = {
        damage = 5,
        hit = 3,
        speed = 13,
        commonness = 10,
        acquire_weight = 0,
        price = 10,
        skill_id = "SK_MACES_FLAILS",
        min_2h_size_id = "SIZE_LITTLE",
        min_1h_size_id = "SIZE_LITTLE",
        ammo_id = "MI_NONE",
        damage_flags = {
            "DAMV_CRUSHING",
        },
        brand_weights = {
            {
                brand_id = brands.NORMAL,
                weight = 9,
            },
            {
                brand_id = brands.SPECTRAL,
                weight = 1,
            },
        },
    },
    -- Source: crawl-ref/source/item-prop.cc
    generation = {
        mode = "random",
        commonness = 10,
    },
}

register.definition(categories.ITEMS, definition)

return definition
