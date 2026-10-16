-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-prop.cc
-- Name Line: 424
-- Property Source: crawl-ref/source/item-prop.cc
-- Property Line: 424

local categories = require("constants.catalog")
local brands = require("constants.weapon_brands")

local definition = {
    id = "WPN_SACRED_SCOURGE",
    name = "sacred scourge",
    glyph = 41,
    class = "OBJ_WEAPONS",
    class_value = 0,
    subtype_value = 51,
    slot = "weapon",
    weapon_skill = "SK_MACES_FLAILS",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc:424
    naming = {
        text = "sacred scourge",
        kind = "static",
    },
    explicitly_removed = false,
    weapon = {
        damage = 12,
        hit = 0,
        speed = 11,
        commonness = 0,
        acquire_weight = 0,
        price = 200,
        skill_id = "SK_MACES_FLAILS",
        min_2h_size_id = "SIZE_LITTLE",
        min_1h_size_id = "SIZE_LITTLE",
        ammo_id = "MI_NONE",
        damage_flags = {
            "DAMV_SLASHING",
        },
        brand_weights = {
            {
                brand_id = brands.HOLY_WRATH,
                weight = 100,
            },
        },
    },
    -- Source: crawl-ref/source/item-prop.cc
    generation = {
        mode = "random",
        commonness = 0,
    },
}

register.definition(categories.ITEMS, definition)

return definition
