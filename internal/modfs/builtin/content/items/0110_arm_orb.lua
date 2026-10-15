-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-prop.cc
-- Name Line: 149
-- Property Source: crawl-ref/source/item-prop.cc
-- Property Line: 149

local categories = require("constants.catalog")

local definition = {
    id = "ARM_ORB",
    name = "orb",
    glyph = 91,
    class = "OBJ_ARMOUR",
    class_value = 2,
    subtype_value = 42,
    slot = "shield",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc:149
    naming = {
        text = "orb",
        kind = "static",
    },
    explicitly_removed = false,
    armour = {
        ac = 0,
        ev = 0,
        price = 90,
        acquire_weight = 0,
        slot_id = "EQ_SHIELD",
        fit_min_id = "SIZE_LITTLE",
        fit_max_id = "SIZE_GIANT",
        mundane = true,
        flags = mod.null,
    },
}

register.definition(categories.ITEMS, definition)

return definition
