-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-prop.cc
-- Name Line: 474
-- Property Source: crawl-ref/source/item-prop.cc
-- Property Line: 474

local categories = require("constants.catalog")

local definition = {
    id = "WPN_QUICK_BLADE",
    name = "quick blade",
    glyph = 41,
    class = "OBJ_WEAPONS",
    class_value = 0,
    subtype_value = 11,
    slot = "weapon",
    weapon_skill = "SK_SHORT_BLADES",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc:474
    naming = {
        text = "quick blade",
        kind = "static",
    },
    explicitly_removed = false,
    weapon = {
        damage = 4,
        hit = 6,
        speed = 7,
        commonness = 0,
        acquire_weight = 2,
        price = 150,
        skill_id = "SK_SHORT_BLADES",
        min_2h_size_id = "SIZE_LITTLE",
        min_1h_size_id = "SIZE_LITTLE",
        ammo_id = "MI_NONE",
        damage_flags = {
            "DAMV_PIERCING",
        },
        brand_weights = mod.null,
    },
}

register.definition(categories.ITEMS, definition)

return definition
