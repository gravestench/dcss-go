-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-prop.cc
-- Name Line: 645
-- Property Source: crawl-ref/source/item-prop.cc
-- Property Line: 645

local categories = require("constants.catalog")

local definition = {
    id = "WPN_ARBALEST",
    name = "arbalest",
    glyph = 41,
    class = "OBJ_WEAPONS",
    class_value = 0,
    subtype_value = 29,
    slot = "weapon",
    weapon_skill = "SK_RANGED_WEAPONS",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc:645
    naming = {
        text = "arbalest",
        kind = "static",
    },
    explicitly_removed = false,
    weapon = {
        damage = 17,
        hit = -2,
        speed = 19,
        commonness = 5,
        acquire_weight = 10,
        price = 45,
        skill_id = "SK_RANGED_WEAPONS",
        min_2h_size_id = "SIZE_LITTLE",
        min_1h_size_id = "NUM_SIZE_LEVELS",
        ammo_id = "MI_BOLT",
        damage_flags = {
            "DAMV_NON_MELEE",
        },
        brand_weights = {
            {
                brand_id = "SPWPN_NORMAL",
                weight = 58,
            },
            {
                brand_id = "SPWPN_FLAMING",
                weight = 16,
            },
            {
                brand_id = "SPWPN_FREEZING",
                weight = 16,
            },
            {
                brand_id = "SPWPN_VORPAL",
                weight = 10,
            },
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition
