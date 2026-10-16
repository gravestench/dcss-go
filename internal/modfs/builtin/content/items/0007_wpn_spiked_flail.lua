-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-prop.cc
-- Name Line: 375
-- Property Source: crawl-ref/source/item-prop.cc
-- Property Line: 375

local categories = require("constants.catalog")

local definition = {
    id = "WPN_SPIKED_FLAIL",
    name = "spiked flail",
    glyph = 41,
    class = "OBJ_WEAPONS",
    class_value = 0,
    subtype_value = 6,
    slot = "weapon",
    weapon_skill = "SK_MACES_FLAILS",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc:375
    naming = {
        text = "spiked flail",
        kind = "static",
    },
    explicitly_removed = false,
    weapon = {
        damage = 5,
        hit = 3,
        speed = 13,
        commonness = 0,
        acquire_weight = 0,
        price = 0,
        skill_id = "SK_MACES_FLAILS",
        min_2h_size_id = "SIZE_LITTLE",
        min_1h_size_id = "SIZE_LITTLE",
        ammo_id = "MI_NONE",
        damage_flags = {
            "DAMV_CRUSHING",
        },
        brand_weights = mod.null,
    },
    -- Source: crawl-ref/source/item-prop.cc
    generation = {
        mode = "random",
        commonness = 0,
    },
}

register.definition(categories.ITEMS, definition)

return definition
