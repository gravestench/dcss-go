-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-prop.cc
-- Name Line: 165
-- Property Source: crawl-ref/source/item-prop.cc
-- Property Line: 165

local categories = require("constants.catalog")

local definition = {
    id = "ARM_SWAMP_DRAGON_ARMOUR",
    name = "swamp dragon scales",
    glyph = 91,
    class = "OBJ_ARMOUR",
    class_value = 2,
    subtype_value = 32,
    slot = "body",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc:165
    naming = {
        text = "swamp dragon scales",
        kind = "static",
    },
    explicitly_removed = false,
    armour = {
        ac = 7,
        ev = -70,
        price = 500,
        acquire_weight = 25,
        slot_id = "EQ_BODY_ARMOUR",
        fit_min_id = "SIZE_LITTLE",
        fit_max_id = "SIZE_GIANT",
        mundane = false,
        flags = {
            {
                id = "ARMF_RES_POISON",
                level = 1,
            },
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition
