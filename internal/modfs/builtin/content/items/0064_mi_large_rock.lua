-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-prop.cc
-- Name Line: 676
-- Property Source: crawl-ref/source/item-prop.cc
-- Property Line: 676

local categories = require("constants.catalog")

local definition = {
    id = "MI_LARGE_ROCK",
    name = "large rock",
    glyph = 40,
    class = "OBJ_MISSILES",
    class_value = 1,
    subtype_value = 6,
    stackable = true,
    -- Source: crawl-ref/source/item-prop.cc:676
    naming = {
        text = "large rock",
        kind = "static",
    },
    explicitly_removed = false,
    missile = {
        damage = 20,
        mulch_rate = 25,
        price = 7,
    },
}

register.definition(categories.ITEMS, definition)

return definition
