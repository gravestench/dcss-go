-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-prop.cc
-- Name Line: 525
-- Property Source: crawl-ref/source/item-prop.cc
-- Property Line: 525

local categories = require("constants.catalog")

local definition = {
    id = "WPN_BLESSED_DOUBLE_SWORD",
    name = "old double sword",
    glyph = 41,
    class = "OBJ_WEAPONS",
    class_value = 0,
    subtype_value = 49,
    slot = "weapon",
    weapon_skill = "SK_LONG_BLADES",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc:525
    naming = {
        text = "old double sword",
        kind = "static",
    },
    explicitly_removed = false,
    weapon = {
        damage = 15,
        hit = -1,
        speed = 15,
        commonness = 0,
        acquire_weight = 0,
        price = 0,
        skill_id = "SK_LONG_BLADES",
        min_2h_size_id = "SIZE_LITTLE",
        min_1h_size_id = "SIZE_MEDIUM",
        ammo_id = "MI_NONE",
        damage_flags = {
            "DAMV_SLICING",
        },
        brand_weights = mod.null,
    },
}

register.definition(categories.ITEMS, definition)

return definition
