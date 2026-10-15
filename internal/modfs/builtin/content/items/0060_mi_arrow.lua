-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-prop.cc
-- Name Line: 674
-- Property Source: crawl-ref/source/item-prop.cc
-- Property Line: 674

local categories = require("constants.catalog")

local definition = {
    id = "MI_ARROW",
    name = "arrow",
    glyph = 40,
    class = "OBJ_MISSILES",
    class_value = 1,
    subtype_value = 2,
    stackable = true,
    -- Source: crawl-ref/source/item-prop.cc:674
    naming = {
        text = "arrow",
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
