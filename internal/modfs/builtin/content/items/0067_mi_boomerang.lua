-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-prop.cc
-- Name Line: 680
-- Property Source: crawl-ref/source/item-prop.cc
-- Property Line: 680

local categories = require("constants.catalog")

local definition = {
    id = "MI_BOOMERANG",
    name = "boomerang",
    glyph = 40,
    class = "OBJ_MISSILES",
    class_value = 1,
    subtype_value = 9,
    stackable = true,
    -- Source: crawl-ref/source/item-prop.cc:680
    naming = {
        text = "boomerang",
        kind = "static",
    },
    explicitly_removed = false,
    missile = {
        damage = 6,
        mulch_rate = 20,
        price = 5,
    },
}

register.definition(categories.ITEMS, definition)

return definition
