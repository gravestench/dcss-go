-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-prop.cc
-- Name Line: 675
-- Property Source: crawl-ref/source/item-prop.cc
-- Property Line: 675

local categories = require("constants.catalog")

local definition = {
    id = "MI_BOLT",
    name = "bolt",
    glyph = 40,
    class = "OBJ_MISSILES",
    class_value = 1,
    subtype_value = 3,
    stackable = true,
    -- Source: crawl-ref/source/item-prop.cc:675
    naming = {
        text = "bolt",
        kind = "static",
    },
    explicitly_removed = true,
    missile = {
        damage = 0,
        mulch_rate = 1,
        price = 2,
    },
}

register.definition(categories.ITEMS, definition)

return definition
