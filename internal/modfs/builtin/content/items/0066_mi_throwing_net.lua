-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-prop.cc
-- Name Line: 679
-- Property Source: crawl-ref/source/item-prop.cc
-- Property Line: 679

local categories = require("constants.catalog")

local definition = {
    id = "MI_THROWING_NET",
    name = "throwing net",
    glyph = 40,
    class = "OBJ_MISSILES",
    class_value = 1,
    subtype_value = 8,
    stackable = true,
    -- Source: crawl-ref/source/item-prop.cc:679
    naming = {
        text = "throwing net",
        kind = "static",
    },
    explicitly_removed = false,
    missile = {
        damage = 0,
        mulch_rate = 0,
        price = 30,
    },
}

register.definition(categories.ITEMS, definition)

return definition
