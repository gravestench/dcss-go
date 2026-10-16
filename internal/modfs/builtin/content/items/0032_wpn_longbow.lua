-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-prop.cc
-- Name Line: 648
-- Property Source: crawl-ref/source/item-prop.cc
-- Property Line: 648

local categories = require("constants.catalog")
local brands = require("constants.weapon_brands")

local definition = {
    id = "WPN_LONGBOW",
    name = "longbow",
    glyph = 41,
    class = "OBJ_WEAPONS",
    class_value = 0,
    subtype_value = 31,
    slot = "weapon",
    weapon_skill = "SK_RANGED_WEAPONS",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc:648
    naming = {
        text = "longbow",
        kind = "static",
    },
    explicitly_removed = false,
    weapon = {
        damage = 12,
        hit = 0,
        speed = 17,
        commonness = 2,
        acquire_weight = 10,
        price = 65,
        skill_id = "SK_RANGED_WEAPONS",
        min_2h_size_id = "SIZE_MEDIUM",
        min_1h_size_id = "NUM_SIZE_LEVELS",
        ammo_id = "MI_ARROW",
        damage_flags = {
            "DAMV_NON_MELEE",
        },
        brand_weights = {
            {
                brand_id = brands.NORMAL,
                weight = 58,
            },
            {
                brand_id = brands.FLAMING,
                weight = 16,
            },
            {
                brand_id = brands.FREEZING,
                weight = 16,
            },
            {
                brand_id = brands.VORPAL,
                weight = 10,
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
