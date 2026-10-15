-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-prop.cc
-- Name Line: 593
-- Property Source: crawl-ref/source/item-prop.cc
-- Property Line: 593

local categories = require("constants.catalog")

local definition = {
    id = "WPN_STAFF",
    name = "staff",
    glyph = 41,
    class = "OBJ_WEAPONS",
    class_value = 0,
    subtype_value = 40,
    slot = "weapon",
    weapon_skill = "SK_STAVES",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc:593
    naming = {
        text = "staff",
        kind = "static",
    },
    explicitly_removed = false,
    weapon = {
        damage = 5,
        hit = 5,
        speed = 12,
        commonness = 0,
        acquire_weight = 0,
        price = 15,
        skill_id = "SK_STAVES",
        min_2h_size_id = "SIZE_LITTLE",
        min_1h_size_id = "SIZE_MEDIUM",
        ammo_id = "MI_NONE",
        damage_flags = {
            "DAMV_CRUSHING",
        },
        brand_weights = mod.null,
    },
}

register.definition(categories.ITEMS, definition)

return definition
