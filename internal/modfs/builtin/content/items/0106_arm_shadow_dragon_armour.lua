-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-prop.cc
-- Name Line: 175
-- Property Source: crawl-ref/source/item-prop.cc
-- Property Line: 175

local categories = require("constants.catalog")

local definition = {
    id = "ARM_SHADOW_DRAGON_ARMOUR",
    name = "shadow dragon scales",
    glyph = 91,
    class = "OBJ_ARMOUR",
    class_value = 2,
    subtype_value = 38,
    slot = "body",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc:175
    naming = {
        text = "shadow dragon scales",
        kind = "static",
    },
    explicitly_removed = false,
    armour = {
        ac = 11,
        ev = -150,
        price = 800,
        acquire_weight = 25,
        slot_id = "EQ_BODY_ARMOUR",
        fit_min_id = "SIZE_LITTLE",
        fit_max_id = "SIZE_GIANT",
        mundane = false,
        flags = {
            {
                id = "ARMF_STEALTH",
                level = 4,
            },
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition
