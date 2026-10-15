-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-prop.cc
-- Name Line: 678
-- Property Source: crawl-ref/source/item-prop.cc
-- Property Line: 678

local categories = require("constants.catalog")

local definition = {
    id = "MI_JAVELIN",
    name = "javelin",
    glyph = 40,
    class = "OBJ_MISSILES",
    class_value = 1,
    subtype_value = 4,
    stackable = true,
    -- Source: crawl-ref/source/item-prop.cc:678
    naming = {
        text = "javelin",
        kind = "static",
    },
    explicitly_removed = false,
    missile = {
        damage = 10,
        mulch_rate = 20,
        price = 8,
    },
}

register.definition(categories.ITEMS, definition)

return definition
