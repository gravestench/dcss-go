-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-prop.cc
-- Name Line: 651
-- Property Source: crawl-ref/source/item-prop.cc
-- Property Line: 651

local categories = require("constants.catalog")

local definition = {
    id = "WPN_TRIPLE_CROSSBOW",
    name = "triple crossbow",
    glyph = 41,
    class = "OBJ_WEAPONS",
    class_value = 0,
    subtype_value = 55,
    slot = "weapon",
    weapon_skill = "SK_RANGED_WEAPONS",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc:651
    naming = {
        text = "triple crossbow",
        kind = "static",
    },
    explicitly_removed = false,
    weapon = {
        damage = 23,
        hit = -2,
        speed = 23,
        commonness = 0,
        acquire_weight = 2,
        price = 100,
        skill_id = "SK_RANGED_WEAPONS",
        min_2h_size_id = "SIZE_SMALL",
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
