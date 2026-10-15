-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-prop.cc
-- Name Line: 116
-- Property Source: crawl-ref/source/item-prop.cc
-- Property Line: 116

local categories = require("constants.catalog")

local definition = {
    id = "ARM_SCARF",
    name = "scarf",
    glyph = 91,
    class = "OBJ_ARMOUR",
    class_value = 2,
    subtype_value = 41,
    slot = "cloak",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc:116
    naming = {
        text = "scarf",
        kind = "static",
    },
    explicitly_removed = false,
    armour = {
        ac = 0,
        ev = 0,
        price = 50,
        acquire_weight = 0,
        slot_id = "EQ_CLOAK",
        fit_min_id = "SIZE_LITTLE",
        fit_max_id = "SIZE_LARGE",
        mundane = true,
        flags = mod.null,
    },
}

register.definition(categories.ITEMS, definition)

return definition
