-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-prop.cc
-- Name Line: 446
-- Property Source: crawl-ref/source/item-prop.cc
-- Property Line: 446

local categories = require("constants.catalog")

local definition = {
    id = "WPN_GREAT_MACE",
    name = "great mace",
    glyph = 41,
    class = "OBJ_WEAPONS",
    class_value = 0,
    subtype_value = 9,
    slot = "weapon",
    weapon_skill = "SK_MACES_FLAILS",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc:446
    naming = {
        text = "great mace",
        kind = "static",
    },
    explicitly_removed = false,
    weapon = {
        damage = 17,
        hit = -4,
        speed = 17,
        commonness = 3,
        acquire_weight = 10,
        price = 65,
        skill_id = "SK_MACES_FLAILS",
        min_2h_size_id = "SIZE_MEDIUM",
        min_1h_size_id = "NUM_SIZE_LEVELS",
        ammo_id = "MI_NONE",
        damage_flags = {
            "DAMV_CRUSHING",
        },
        brand_weights = {
            {
                brand_id = "SPWPN_PROTECTION",
                weight = 30,
            },
            {
                brand_id = "SPWPN_NORMAL",
                weight = 28,
            },
            {
                brand_id = "SPWPN_HOLY_WRATH",
                weight = 15,
            },
            {
                brand_id = "SPWPN_VORPAL",
                weight = 14,
            },
            {
                brand_id = "SPWPN_DRAINING",
                weight = 10,
            },
            {
                brand_id = "SPWPN_VENOM",
                weight = 5,
            },
            {
                brand_id = "SPWPN_DISTORTION",
                weight = 1,
            },
            {
                brand_id = "SPWPN_ANTIMAGIC",
                weight = 1,
            },
            {
                brand_id = "SPWPN_PAIN",
                weight = 1,
            },
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition
