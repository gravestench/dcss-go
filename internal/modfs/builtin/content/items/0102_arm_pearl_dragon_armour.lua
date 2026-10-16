-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-prop.cc
-- Name Line: 171
-- Property Source: crawl-ref/source/item-prop.cc
-- Property Line: 171

local categories = require("constants.catalog")

local definition = {
    id = "ARM_PEARL_DRAGON_ARMOUR",
    name = "pearl dragon scales",
    glyph = 91,
    class = "OBJ_ARMOUR",
    class_value = 2,
    subtype_value = 34,
    slot = "body",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc:171
    naming = {
        text = "pearl dragon scales",
        kind = "static",
    },
    explicitly_removed = false,
    armour = {
        ac = 10,
        ev = -110,
        price = 1000,
        acquire_weight = 25,
        slot_id = "EQ_BODY_ARMOUR",
        fit_min_id = "SIZE_LITTLE",
        fit_max_id = "SIZE_GIANT",
        mundane = false,
        flags = {
            {
                id = "ARMF_RES_NEG",
                level = 1,
            },
        },
    },
    -- Source: crawl-ref/source/makeitem.cc
    generation = {
        mode = "random",
    },
}

register.definition(categories.ITEMS, definition)

return definition
