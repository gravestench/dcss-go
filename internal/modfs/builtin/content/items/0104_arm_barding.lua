-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-prop.cc
-- Name Line: 144
-- Property Source: crawl-ref/source/item-prop.cc
-- Property Line: 144

local categories = require("constants.catalog")

local definition = {
    id = "ARM_BARDING",
    name = "barding",
    glyph = 91,
    class = "OBJ_ARMOUR",
    class_value = 2,
    subtype_value = 36,
    slot = "boots",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc:144
    naming = {
        text = "barding",
        kind = "static",
    },
    explicitly_removed = false,
    armour = {
        ac = 4,
        ev = -60,
        price = 230,
        acquire_weight = 0,
        slot_id = "EQ_BOOTS",
        fit_min_id = "SIZE_MEDIUM",
        fit_max_id = "SIZE_LARGE",
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
