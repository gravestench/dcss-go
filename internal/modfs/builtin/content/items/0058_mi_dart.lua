-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-prop.cc
-- Name Line: 669
-- Property Source: crawl-ref/source/item-prop.cc
-- Property Line: 669

local categories = require("constants.catalog")

local definition = {
    id = "MI_DART",
    name = "dart",
    glyph = 40,
    class = "OBJ_MISSILES",
    class_value = 1,
    subtype_value = 0,
    stackable = true,
    -- Source: crawl-ref/source/item-prop.cc:669
    naming = {
        text = "dart",
        kind = "static",
    },
    explicitly_removed = false,
    missile = {
        damage = 0,
        mulch_rate = 12,
        price = 2,
    },
}

register.definition(categories.ITEMS, definition)

return definition
