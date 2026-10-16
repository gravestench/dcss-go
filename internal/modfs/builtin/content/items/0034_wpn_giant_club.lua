-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-prop.cc
-- Name Line: 449
-- Property Source: crawl-ref/source/item-prop.cc
-- Property Line: 449

local categories = require("constants.catalog")
local brands = require("constants.weapon_brands")

local definition = {
    id = "WPN_GIANT_CLUB",
    name = "giant club",
    glyph = 41,
    class = "OBJ_WEAPONS",
    class_value = 0,
    subtype_value = 33,
    slot = "weapon",
    weapon_skill = "SK_MACES_FLAILS",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc:449
    naming = {
        text = "giant club",
        kind = "static",
    },
    explicitly_removed = false,
    weapon = {
        damage = 20,
        hit = -6,
        speed = 16,
        commonness = 1,
        acquire_weight = 10,
        price = 17,
        skill_id = "SK_MACES_FLAILS",
        min_2h_size_id = "SIZE_LARGE",
        min_1h_size_id = "NUM_SIZE_LEVELS",
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
        commonness = 1,
    },
}

register.definition(categories.ITEMS, definition)

return definition
