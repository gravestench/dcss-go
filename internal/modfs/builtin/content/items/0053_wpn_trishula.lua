-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-prop.cc
-- Name Line: 581
-- Property Source: crawl-ref/source/item-prop.cc
-- Property Line: 581

local categories = require("constants.catalog")
local brands = require("constants.weapon_brands")

local definition = {
    id = "WPN_TRISHULA",
    name = "trishula",
    glyph = 41,
    class = "OBJ_WEAPONS",
    class_value = 0,
    subtype_value = 52,
    slot = "weapon",
    weapon_skill = "SK_POLEARMS",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc:581
    naming = {
        text = "trishula",
        kind = "static",
    },
    explicitly_removed = false,
    weapon = {
        damage = 13,
        hit = 0,
        speed = 13,
        commonness = 0,
        acquire_weight = 0,
        price = 200,
        skill_id = "SK_POLEARMS",
        min_2h_size_id = "SIZE_LITTLE",
        min_1h_size_id = "SIZE_MEDIUM",
        ammo_id = "MI_NONE",
        damage_flags = {
            "DAMV_PIERCING",
        },
        brand_weights = {
            {
                brand_id = brands.HOLY_WRATH,
                weight = 100,
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
