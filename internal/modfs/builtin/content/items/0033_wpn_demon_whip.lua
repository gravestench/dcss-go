-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-prop.cc
-- Name Line: 421
-- Property Source: crawl-ref/source/item-prop.cc
-- Property Line: 421

local categories = require("constants.catalog")

local definition = {
    id = "WPN_DEMON_WHIP",
    name = "demon whip",
    glyph = 41,
    class = "OBJ_WEAPONS",
    class_value = 0,
    subtype_value = 32,
    slot = "weapon",
    weapon_skill = "SK_MACES_FLAILS",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc:421
    naming = {
        text = "demon whip",
        kind = "static",
    },
    explicitly_removed = false,
    weapon = {
        damage = 11,
        hit = 1,
        speed = 11,
        commonness = 0,
        acquire_weight = 2,
        price = 150,
        skill_id = "SK_MACES_FLAILS",
        min_2h_size_id = "SIZE_LITTLE",
        min_1h_size_id = "SIZE_LITTLE",
        ammo_id = "MI_NONE",
        damage_flags = {
            "DAMV_SLASHING",
        },
        brand_weights = {
            {
                brand_id = "SPWPN_NORMAL",
                weight = 27,
            },
            {
                brand_id = "SPWPN_VENOM",
                weight = 19,
            },
            {
                brand_id = "SPWPN_ELECTROCUTION",
                weight = 16,
            },
            {
                brand_id = "SPWPN_DRAINING",
                weight = 10,
            },
            {
                brand_id = "SPWPN_FLAMING",
                weight = 7,
            },
            {
                brand_id = "SPWPN_FREEZING",
                weight = 7,
            },
            {
                brand_id = "SPWPN_VAMPIRISM",
                weight = 7,
            },
            {
                brand_id = "SPWPN_PAIN",
                weight = 4,
            },
            {
                brand_id = "SPWPN_ANTIMAGIC",
                weight = 3,
            },
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition
