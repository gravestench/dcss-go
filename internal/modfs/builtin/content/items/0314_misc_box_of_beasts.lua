-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 958

local categories = require("constants.catalog")

local definition = {
    id = "MISC_BOX_OF_BEASTS",
    name = "box of beasts",
    glyph = 125,
    class = "OBJ_MISCELLANY",
    class_value = 11,
    subtype_value = 6,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc:958
    naming = {
        text = "box of beasts",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/makeitem.cc
    generation = {
        mode = "random",
    },
}

register.definition(categories.ITEMS, definition)

return definition
