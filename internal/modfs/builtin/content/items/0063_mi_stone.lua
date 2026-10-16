-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-prop.cc
-- Name Line: 673
-- Property Source: crawl-ref/source/item-prop.cc
-- Property Line: 673

local categories = require("constants.catalog")

local definition = {
    id = "MI_STONE",
    name = "stone",
    glyph = 40,
    class = "OBJ_MISSILES",
    class_value = 1,
    subtype_value = 5,
    stackable = true,
    -- Source: crawl-ref/source/item-prop.cc:673
    naming = {
        text = "stone",
        kind = "static",
    },
    explicitly_removed = false,
    missile = {
        damage = 2,
        mulch_rate = 8,
        price = 1,
    },
    -- Source: crawl-ref/source/makeitem.cc
    generation = {
        mode = "random",
    },
}

register.definition(categories.ITEMS, definition)

return definition
