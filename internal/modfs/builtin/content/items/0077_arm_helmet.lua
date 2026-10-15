-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-prop.cc
-- Name Line: 122
-- Property Source: crawl-ref/source/item-prop.cc
-- Property Line: 122

local categories = require("constants.catalog")

local definition = {
    id = "ARM_HELMET",
    name = "helmet",
    glyph = 91,
    class = "OBJ_ARMOUR",
    class_value = 2,
    subtype_value = 9,
    slot = "head",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc:122
    naming = {
        text = "helmet",
        kind = "static",
    },
    explicitly_removed = false,
    armour = {
        ac = 1,
        ev = 0,
        price = 45,
        acquire_weight = 0,
        slot_id = "EQ_HELMET",
        fit_min_id = "SIZE_SMALL",
        fit_max_id = "SIZE_MEDIUM",
        mundane = true,
        flags = mod.null,
    },
}

register.definition(categories.ITEMS, definition)

return definition
