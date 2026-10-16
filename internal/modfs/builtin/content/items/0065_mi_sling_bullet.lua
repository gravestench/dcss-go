-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-prop.cc
-- Name Line: 677
-- Property Source: crawl-ref/source/item-prop.cc
-- Property Line: 677

local categories = require("constants.catalog")

local definition = {
    id = "MI_SLING_BULLET",
    name = "sling bullet",
    glyph = 40,
    class = "OBJ_MISSILES",
    class_value = 1,
    subtype_value = 7,
    stackable = true,
    -- Source: crawl-ref/source/item-prop.cc:677
    naming = {
        text = "sling bullet",
        kind = "static",
    },
    explicitly_removed = true,
    missile = {
        damage = 0,
        mulch_rate = 1,
        price = 5,
    },
    -- Source: crawl-ref/source/makeitem.cc
    generation = {
        mode = "none",
    },
}

register.definition(categories.ITEMS, definition)

return definition
