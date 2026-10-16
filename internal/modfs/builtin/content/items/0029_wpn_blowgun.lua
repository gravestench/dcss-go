-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-prop.cc
-- Name Line: 625
-- Property Source: crawl-ref/source/item-prop.cc
-- Property Line: 625

local categories = require("constants.catalog")

local definition = {
    id = "WPN_BLOWGUN",
    name = "blowgun",
    glyph = 41,
    class = "OBJ_WEAPONS",
    class_value = 0,
    subtype_value = 28,
    slot = "weapon",
    weapon_skill = "SK_THROWING",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc:625
    naming = {
        text = "blowgun",
        kind = "static",
    },
    explicitly_removed = false,
    weapon = {
        damage = 0,
        hit = 2,
        speed = 10,
        commonness = 0,
        acquire_weight = 0,
        price = 0,
        skill_id = "SK_THROWING",
        min_2h_size_id = "SIZE_LITTLE",
        min_1h_size_id = "SIZE_LITTLE",
        ammo_id = "MI_NEEDLE",
        damage_flags = {
            "DAMV_NON_MELEE",
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
