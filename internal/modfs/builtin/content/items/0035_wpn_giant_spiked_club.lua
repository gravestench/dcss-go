-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-prop.cc
-- Name Line: 452
-- Property Source: crawl-ref/source/item-prop.cc
-- Property Line: 452

local categories = require("constants.catalog")

local definition = {
    id = "WPN_GIANT_SPIKED_CLUB",
    name = "giant spiked club",
    glyph = 41,
    class = "OBJ_WEAPONS",
    class_value = 0,
    subtype_value = 34,
    slot = "weapon",
    weapon_skill = "SK_MACES_FLAILS",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc:452
    naming = {
        text = "giant spiked club",
        kind = "static",
    },
    explicitly_removed = false,
    weapon = {
        damage = 22,
        hit = -7,
        speed = 18,
        commonness = 1,
        acquire_weight = 10,
        price = 19,
        skill_id = "SK_MACES_FLAILS",
        min_2h_size_id = "SIZE_LARGE",
        min_1h_size_id = "NUM_SIZE_LEVELS",
        ammo_id = "MI_NONE",
        damage_flags = {
            "DAMV_CRUSHING",
            "DAM_PIERCE",
        },
        brand_weights = {
            {
                brand_id = "SPWPN_NORMAL",
                weight = 9,
            },
            {
                brand_id = "SPWPN_SPECTRAL",
                weight = 1,
            },
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition
