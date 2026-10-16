-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-prop.cc
-- Name Line: 104
-- Property Source: crawl-ref/source/item-prop.cc
-- Property Line: 104

local categories = require("constants.catalog")

local definition = {
    id = "ARM_CRYSTAL_PLATE_ARMOUR",
    name = "crystal plate armour",
    glyph = 91,
    class = "OBJ_ARMOUR",
    class_value = 2,
    subtype_value = 15,
    slot = "body",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc:104
    naming = {
        text = "crystal plate armour",
        kind = "static",
    },
    explicitly_removed = false,
    armour = {
        ac = 14,
        ev = -230,
        price = 800,
        acquire_weight = 500,
        slot_id = "EQ_BODY_ARMOUR",
        fit_min_id = "SIZE_SMALL",
        fit_max_id = "SIZE_MEDIUM",
        mundane = false,
        flags = mod.null,
    },
    -- Source: crawl-ref/source/makeitem.cc
    generation = {
        mode = "random",
    },
}

register.definition(categories.ITEMS, definition)

return definition
