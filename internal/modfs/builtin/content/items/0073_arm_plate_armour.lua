-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-prop.cc
-- Name Line: 102
-- Property Source: crawl-ref/source/item-prop.cc
-- Property Line: 102

local categories = require("constants.catalog")

local definition = {
    id = "ARM_PLATE_ARMOUR",
    name = "plate armour",
    glyph = 91,
    class = "OBJ_ARMOUR",
    class_value = 2,
    subtype_value = 5,
    slot = "body",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc:102
    naming = {
        text = "plate armour",
        kind = "static",
    },
    explicitly_removed = false,
    armour = {
        ac = 10,
        ev = -180,
        price = 230,
        acquire_weight = 1000,
        slot_id = "EQ_BODY_ARMOUR",
        fit_min_id = "SIZE_SMALL",
        fit_max_id = "SIZE_MEDIUM",
        mundane = true,
        flags = mod.null,
    },
    -- Source: crawl-ref/source/makeitem.cc
    generation = {
        mode = "random",
    },
}

register.definition(categories.ITEMS, definition)

return definition
