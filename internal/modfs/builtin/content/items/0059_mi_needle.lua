-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-prop.cc
-- Name Line: 671
-- Property Source: crawl-ref/source/item-prop.cc
-- Property Line: 671

local categories = require("constants.catalog")

local definition = {
    id = "MI_NEEDLE",
    name = "needle",
    glyph = 40,
    class = "OBJ_MISSILES",
    class_value = 1,
    subtype_value = 1,
    stackable = true,
    -- Source: crawl-ref/source/item-prop.cc:671
    naming = {
        text = "needle",
        kind = "static",
    },
    explicitly_removed = false,
    missile = {
        damage = 0,
        mulch_rate = 12,
        price = 2,
    },
    -- Source: crawl-ref/source/makeitem.cc
    generation = {
        mode = "forced",
    },
}

register.definition(categories.ITEMS, definition)

return definition
